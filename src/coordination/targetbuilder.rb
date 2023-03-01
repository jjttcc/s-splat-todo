require 'ruby_contracts'
require 'project'
require 'scheduledevent'
require 'memorandum'

# Builder of s*todo target objects
class TargetBuilder
  include SpecTools, ErrorTools
  include Contracts::DSL

  public

  #####  Access

  # All targets built from specs: Hash[handle -> STodoTarget]
  attr_reader :targets
  # All targets that were edited by 'build_targets'
  attr_reader :edited_targets
  # Hash - 'edited_targets' with time change: STodoTarget => <boolean>
  attr_reader :time_changed_for
  attr_reader :spec_collector
  attr_accessor :existing_targets

  # Have 'targets' been "prepared"?
  def targets_prepared?
    ! self.targets.nil?
  end

  def specs
    self.spec_collector.specs
  end

#!!!!This method probably nmeeds to be retracted/removed:
  def spec_for handle
    result = self.spec_collector.spec_for handle
$log.debug "TargetBuilder.spec_for #{handle} class:"
$log.debug "#{result.class}"
$log.debug "TargetBuilder.spec_for #{handle} type:"
$log.debug "#{result.type}"
$log.debug "TargetBuilder.spec_for - handle #{result.handle}"
    result
  end

  #####  Basic operations

  # Build 'targets'.
  pre '"existing_targets" set' do ! self.existing_targets.nil? end
  post '! targets.nil?' do ! self.targets.nil? end
  def build_targets
    if ! targets_prepared? then
      prepare_targets
    end
    for s in self.specs do
      begin
        t = target_for(s)
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

  private

  attr_writer :targets

  post 'targets.nil?' do self.targets.nil? end
  def initialize spec_collector
    @spec_collector = spec_collector
    @edited_targets = []
    @time_changed_for = {}
    init_target_factory
  end

  # Use spec.type to obtain the appropriate type of builder method (element
  # of @target_factory_for) and call that method to "build" (create or
  # edit, as appropriate) the appropriate target (STodoTarget descendant)
  # based on spec.handle. Return the resulting "built" object.
  # If spec.parent != nil and spec.parent is invalid (
  # @existing_targets[spec.parent].nil?), an exception is thrown after
  # logging an appropriate warning message.
  # postcondition: implies(! result.nil?, result.handle == spec.handle)
  def target_for spec
    result = nil
    builder = @target_factory_for[builder_key spec]
$log.warn "[t_for] spec: #{spec.inspect}"
$log.warn "[t_for] builder: #{builder.inspect}"
    if builder == nil then
      if spec.type == TEMPLATE_TYPE then
        $log.warn "(Ignoring spec '#{spec.handle}' with '#{spec.type}' type.)"
      else
        warning = "Invalid type for spec: #{spec.type} (title: #{spec.title})"
        $log.warn warning
      end
    else
      # Build the "target".
$log.warn "[t_for] spec: #{spec.inspect}"
      t = builder.call(spec)
$log.warn "[t_for] t: #{t.inspect}"
$log.warn "[t_for] result[0] #{result}"
      if t != nil and t.valid? then
        result = t
$log.warn "[t_for] result[1] #{result}"
      elsif t != nil then
        $log.warn "#{t.handle} is not valid [#{t}]"
$log.warn "[t_for] result[1] #{result}"
      end
    end
$log.warn "[t_for] result[2] #{result.inspect}"
    result
  end

  # Edit the target from @existing_targets, if one exists, whose handle
  # matches 'spec.handle', such that its fields are changed according to
  # fields that are set (not nil) in 'spec'.  Add the edited target to
  # @edited_targets.  Return nil to indicate that now new STodoTarget has
  # been created.
  def edit_target(spec)
    result = nil
$log.warn "edit_target: spec.handle: #{spec.handle}"
$log.warn "edit_target: existing_targets.nil?: #{self.existing_targets.nil?}"
    if self.existing_targets != nil && spec.handle then
      t = self.existing_targets[spec.handle]
      if t.type == EDIT then
#!!!!!temporary experiment:
#!!!      if true || t.type == EDIT then
        result = t
      end
      if t then
$log.warn "#{t.handle} found"
        old_time = t.time.clone
        t.modify_fields(spec, self.existing_targets)
        if old_time != t.time then
          @time_changed_for[t] = true
        end
$log.warn "edit_target: edited_targets.count: #{self.edited_targets.count}"
        @edited_targets << t
$log.warn "edit_target: t (#{t.handle}) added to @edited_targets"
$log.warn "edit_target: edited_targets.count: #{self.edited_targets.count}"
      else
$log.warn "t NOT found"
      end
    end
####!!!!Note: This stuff is in flux!!!!
    result
nil
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
      CORRECTION  => lambda do |spec| edit_target(spec) end,
#!!!!:
EDIT        => lambda do |spec| edit_target(spec) end,
    }
    # Define "type" aliases.
    @target_factory_for[TASK] = @target_factory_for[TASK_ALIAS1]
    @target_factory_for[NOTE_ALIAS1] = @target_factory_for[NOTE]
    @target_factory_for[NOTE_ALIAS2] = @target_factory_for[NOTE]
    @target_factory_for[APPOINTMENT_ALIAS1] = @target_factory_for[APPOINTMENT]
    @target_factory_for[APPOINTMENT_ALIAS2] = @target_factory_for[APPOINTMENT]
  end

  ##### Hook methods

  post 'targets exist' do ! self.targets.nil? end
  def prepare_targets
    self.targets = []   # redefine if needed
  end

  # key for Proc/builder
  def builder_key spec
    spec.type
  end

end
