require 'ruby_contracts'
require 'stodo_target_factory'
require 'project'
require 'scheduledevent'
require 'memorandum'

# Builder of s*todo target objects
class TargetBuilder
  include SpecTools, ErrorTools
  include Contracts::DSL

  public

  EDIT_MODE, CREATE_MODE = 'edit', 'create'

  # Set 'processing_mode' to EDIT_MODE.
  post :edit_mode do self.processing_mode == EDIT_MODE end
  def set_edit_mode
    self.processing_mode = EDIT_MODE
  end

  # Set 'processing_mode' to CREATE_MODE.
  post :create_mode do self.processing_mode == CREATE_MODE end
  def set_create_mode
    self.processing_mode = CREATE_MODE
  end

  # Set 'processing_mode' to 'm'.
  pre ' m is edit or create' do |m| m == EDIT_MODE || m == CREATE_MODE end
  post 'mode set to "m"' do |res, m| self.processing_mode == m end
  def set_processing_mode(m)
    self.processing_mode = m
  end

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

  #####  Element change

  # Set 'spec_collector' to 'sc' and clear attributes:
  #   - [to-do: list of attrs]
  pre  :sc_exists do |sc| ! sc.nil? end
  post :spec_c_set do |result, sc| self.spec_collector == sc end
  def spec_collector=(sc)
    @spec_collector = sc
    prepare_targets
    @edited_targets = []
    @time_changed_for = {}
  end

  #####  Basic operations

  # Process STodoTarget objects according to self.specs, and, based on
  # 'processing_mode', create a new STodoTarget object or edit the
  # existing one that corresponds to the specification.
  # Add any existing 'targets' that were edited to self.edited_targets.
  pre '"existing_targets" set' do ! existing_targets.nil? end
  pre 'specs exist' do ! specs.nil? end
  pre 'edited_targets empty' do
    ! edited_targets.nil? && edited_targets.empty?
  end
  post 'targets exist' do ! targets.nil? end
  post 'edited_targets exist' do ! edited_targets.nil? end
  def process_targets
logf = File.new("/tmp/process_targets", "w")
    if ! targets_prepared? then
      prepare_targets
    end
    for s in self.specs do
logf.puts("TB.proc targets: s: #{s}")
logf.flush
      begin
        s.existing_targets = self.existing_targets
        if new_target_needed(s) then
logf.puts("TB.proc targets: new_target_needed")
logf.flush
          t = new_target(s)
        else
logf.puts("TB.proc targets: NOT new_target_needed")
logf.flush
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

  pre  'collector exists' do |spec_collector| ! spec_collector.nil? end
  post 'targets.nil?' do targets.nil? end
  post 'edited_targets empty' do
    ! edited_targets.nil? && edited_targets.empty?
  end
  # Set self.processing_mode to CREATE_MODE, unless overridden in descendant.
  # Initialize @spec_collector, @edited_targets, @time_changed_for.
  # Initialize @target_factory_for ("target factory" hash table).
  def initialize spec_collector, config
    @spec_collector = spec_collector
    @edited_targets = []
    @time_changed_for = {}
    self.processing_mode = CREATE_MODE
#!!!    init_target_factory(config.stodo_target_child_container_factory)
    init_target_factory(config)
  end

  # Build and return a new STodoTarget based on 'spec'. If 'spec' is
  # invalid, log the error and return nil.
  def new_target spec
    result = nil
    builder = @target_factory_for[builder_key spec]
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
      if t != nil && t.valid? then
        result = t
      elsif t != nil then
        msg = "#{t.handle} is not valid"
        if ! t.invalidity_reason.nil? then
          msg = "#{msg}: #{t.invalidity_reason}"
        end
        $log.warn msg
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

  def init_target_factory(config)
    @target_factory_for = STodoTargetFactory.new(config)
  end

=begin
  def init_target_factory(config)
    cc_factory = config.stodo_target_child_container_factory
    @target_factory_for = {
      PROJECT     => lambda do |spec| Project.new(spec, cc_factory.call) end,
      TASK_ALIAS1 => lambda do |spec|
        Task.new(spec, cc_factory.call) end,
      NOTE        => lambda do |spec| Memorandum.new(spec, cc_factory.call) end,
      APPOINTMENT => lambda do |spec| ScheduledEvent.new(spec,
                                                         cc_factory.call) end,
    }
    # Define "type" aliases.
    @target_factory_for[TASK] = @target_factory_for[TASK_ALIAS1]
    @target_factory_for[NOTE_ALIAS1] = @target_factory_for[NOTE]
    @target_factory_for[NOTE_ALIAS2] = @target_factory_for[NOTE]
    @target_factory_for[APPOINTMENT_ALIAS1] = @target_factory_for[APPOINTMENT]
    @target_factory_for[APPOINTMENT_ALIAS2] = @target_factory_for[APPOINTMENT]
  end

#old:
  def older___init_target_factory cc_factory
    @target_factory_for = {
      PROJECT     => lambda do |spec| Project.new(spec, cc_factory.call) end,
      TASK_ALIAS1 => lambda do |spec|
        Task.new(spec, cc_factory.call) end,
      NOTE        => lambda do |spec| Memorandum.new(spec, cc_factory.call) end,
      APPOINTMENT => lambda do |spec| ScheduledEvent.new(spec,
                                                         cc_factory.call) end,
    }
    # Define "type" aliases.
    @target_factory_for[TASK] = @target_factory_for[TASK_ALIAS1]
    @target_factory_for[NOTE_ALIAS1] = @target_factory_for[NOTE]
    @target_factory_for[NOTE_ALIAS2] = @target_factory_for[NOTE]
    @target_factory_for[APPOINTMENT_ALIAS1] = @target_factory_for[APPOINTMENT]
    @target_factory_for[APPOINTMENT_ALIAS2] = @target_factory_for[APPOINTMENT]
  end
=end

  # Does a new STodoTarget need to be created?
  def new_target_needed(s)
    in_creation_mode? && builder_key(s) != CORRECTION
  end

  ##### Hook methods

  def builder_key spec
    spec.type
  end

end
