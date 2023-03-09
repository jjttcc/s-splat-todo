require 'ruby_contracts'
require 'project'
require 'scheduledevent'
require 'memorandum'

# Builder of s*todo target objects
class TargetBuilder
  include SpecTools, ErrorTools
  include Contracts::DSL

  public

  EDIT_MODE, CREATE_MODE = 'edit', 'create'

  public

  #####  Access

  # All targets built from specs: Hash[handle -> STodoTarget]
  attr_reader :targets
  # All targets that were edited by 'process_targets'
  attr_reader :edited_targets
  # mode for target-object processing - 'edit' or 'create'
  attr_reader :processing_mode
  # Hash - 'edited_targets' with time change: STodoTarget => <boolean>
  attr_reader :time_changed_for
  attr_reader :spec_collector
  attr_accessor :existing_targets

  def specs
    self.spec_collector.specs
  end

  #####  Status report

  # Have 'targets' been "prepared"?
  def targets_prepared?
    ! self.targets.nil?
  end

  # Are we editing existing objects?
  def in_editing_mode?
    self.processing_mode == EDIT_MODE
  end

  # Are we creating new objects?
  def in_creation_mode?
    self.processing_mode == CREATE_MODE
  end

  #####  Basic operations

  # Process STodoTarget objects according to self.specs, and, based on
  # 'processing_mode', create a new STodoTarget object or edit the
  # existing one that corresponds to the specification.
  pre '"existing_targets" set if editing' do
    implies(in_editing_mode?, ! self.existing_targets.nil?)
  end
  pre 'specs exist' do ! specs.nil? end
  post '! targets.nil?' do ! self.targets.nil? end
  def process_targets
    if ! targets_prepared? then
      prepare_targets
    end
    for s in self.specs do
      begin
        if new_target_needed(s) then
          t = new_target(s)
        else
          edit_target(s)
          t = self.last_edited_target
        end
        if t != nil then
          self.targets << t
        else
          msg = "nil target for spec: #{s.handle} (type #{s.type})"
          if s.type == CORRECTION || s.type == TEMPLATE_TYPE then
            msg += " (expected)"
          end
          $log.debug msg
        end
      rescue Exception => e
        # Processing of 't' caused an exception, so it will not be added to
        # self.targets and we'll continue to the next iteration.
        $log.warn e
      end
    end
  end

  ##### Public hook methods

  post 'targets exist' do ! self.targets.nil? end
  def prepare_targets
    self.targets = []   # redefine if needed
  end

  protected

  attr_accessor :last_edited_target

  private

  attr_writer :targets, :processing_mode

  post 'targets.nil?' do self.targets.nil? end
  # Set self.processing_mode to CREATE_MODE, unless overridden in descendant.
  # Initialize @spec_collector, @edited_targets, @time_changed_for.
  # Initialize @target_factory_for ("target factory" hash table).
  def initialize spec_collector
    @spec_collector = spec_collector
    @edited_targets = []
    @time_changed_for = {}
    self.processing_mode = CREATE_MODE
    init_target_factory
  end

  # Build and return a new STodoTarget based on 'spec'. If 'spec' is
  # invalid, log the error and return nil.
  def new_target spec
    result = nil
    builder = @target_factory_for[builder_key spec]
    $log.debug "[new_target] spec: #{spec.handle}, #{spec.type}"
    $log.debug "[new_target] builder: #{builder.inspect}"
    if builder == nil then
      if spec.type == TEMPLATE_TYPE then
        $log.warn "(Ignoring spec '#{spec.handle}' with '#{spec.type}' type.)"
      else
        warning = "Invalid type for spec: #{spec.type} (title: #{spec.title})"
        $log.warn warning
      end
    else
      # Build the "target".
      t = builder.call(spec)
      $log.debug "[new_target] t: #{t.inspect}"
      if t != nil && t.valid? then
        result = t
      elsif t != nil then
        $log.warn "#{t.handle} is not valid [#{t}]"
      end
    end
    $log.debug "[new_target] result[2] #{result.inspect}"
    result
  end

  # Edit the target from @existing_targets, if one exists, whose handle
  # matches 'spec.handle', such that its fields are changed according to
  # fields that are set (not nil) in 'spec'.  Add the edited target to
  # @edited_targets.
  def edit_target(spec)
    self.last_edited_target = nil
    $log.debug "edit_target: spec.handle: #{spec.handle}"
    if self.existing_targets != nil && spec.handle then
      t = self.existing_targets[spec.handle]
      self.last_edited_target = t
      if t then
        $log.debug "#{t.handle} found"
        old_time = t.time.clone
        t.modify_fields(spec, self.existing_targets)
        if old_time != t.time then
          @time_changed_for[t] = true
        end
        @edited_targets << t
        $log.debug "edit_target: t (#{t.handle}) added to @edited_targets"
        $log.debug "edit_target: edited_targets.count: "
          "#{self.edited_targets.count}"
      else
        $log.debug "t NOT found"
      end
    end
  end

  # Edit the target from @existing_targets, if one exists, whose handle
  # matches 'spec.handle', such that its fields are changed according to
  # fields that are set (not nil) in 'spec'.  Add the edited target to
  # @edited_targets.  Return nil to indicate that now new STodoTarget has
  # been created.
  def previous__edit_target(spec)
    if @existing_targets != nil && spec.handle then
      tgt_handle = spec.handle
      t = @existing_targets[tgt_handle]
      if t then
        old_time = t.time.clone
        t.modify_fields(spec, @existing_targets)
        if old_time != t.time then
          @time_changed_for[t] = true
        end
        @edited_targets << t
      end
    end
    nil
  end

  def init_target_factory
    @target_factory_for = {
      PROJECT     => lambda do |spec| Project.new(spec) end,
      TASK_ALIAS1 => lambda do |spec| Task.new(spec) end,
      NOTE        => lambda do |spec| Memorandum.new(spec) end,
      APPOINTMENT => lambda do |spec| ScheduledEvent.new(spec) end,
    }
    # Define "type" aliases.
    @target_factory_for[TASK] = @target_factory_for[TASK_ALIAS1]
    @target_factory_for[NOTE_ALIAS1] = @target_factory_for[NOTE]
    @target_factory_for[NOTE_ALIAS2] = @target_factory_for[NOTE]
    @target_factory_for[APPOINTMENT_ALIAS1] = @target_factory_for[APPOINTMENT]
    @target_factory_for[APPOINTMENT_ALIAS2] = @target_factory_for[APPOINTMENT]
  end

  # Does a new STodoTarget need to be created?
  def new_target_needed(s)
    in_creation_mode? && builder_key(s) != CORRECTION
  end

  ##### Hook methods

  def builder_key spec
    spec.type
  end

end
