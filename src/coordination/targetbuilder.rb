require 'project'
require 'scheduledevent'
require 'memorandum'

# Builder of s*todo target objects
class TargetBuilder
  include SpecTools, ErrorTools

  public

  # All targets built from specs: Hash[handle -> STodoTarget]
  attr_reader :targets
  # All targets that were edited by 'build_targets'
  attr_reader :edited_targets
  # Hash - 'edited_targets' with time change: STodoTarget => <boolean>
  attr_reader :time_changed_for
  attr_reader :spec_collector

  def specs
    @spec_collector.specs
  end

  # Build 'targets'.
  # postcondition: targets != nil
  def build_targets existing_targets
    @existing_targets = existing_targets
    @targets = []
    for s in self.specs do
      t = target_for(s)
      if t != nil then
        @targets << t
      else
        $log.debug "nil target for spec: #{s.inspect}"
      end
    end
    assert_postcondition('targets != nil') { targets != nil }
  end

  private

  def initialize spec_collector
    @spec_collector = spec_collector
    @edited_targets = []
    @time_changed_for = {}
    init_target_factory
  end

  def target_for spec
    result = nil
    builder = @target_factory_for[spec.type]
    if builder == nil then
      warning = "Invalid type for spec - title: \"#{spec.title}\" " +
        "type: #{spec.type}"
      $log.warn warning
    else
      # Build the "target".
      t = builder.call(spec)
      if t != nil and t.valid? then
        result = t
      elsif t != nil then
        $log.warn "#{t.handle} is not valid [#{t}]"
      end
    end
    result
  end

  # Edit the target from @existing_targets, if one exists, whose handle
  # matches 'specs.handle', such that its fields are changed according to
  # fields that are set (not nil) in 'specs'.  Add the edited target to
  # @edited_targets.  Return nil to indicate that now new STodoTarget has
  # been created.
  def edit_target(specs)
    if @existing_targets != nil && specs.handle then
      tgt_handle = specs.handle
      t = @existing_targets[tgt_handle]
      if t then
        old_time = t.time.clone
        t.modify_fields(specs)
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
      'project' => lambda do |spec| Project.new(spec) end,
      'action' => lambda do |spec| CompositeTask.new(spec) end,
      'note' => lambda do |spec| Memorandum.new(spec) end,
      'appointment' => lambda do |spec| ScheduledEvent.new(spec) end,
      'correction' => lambda do |spec| edit_target(spec) end,
    }
    # Define "type" aliases.
    @target_factory_for['task'] = @target_factory_for['action']
    @target_factory_for['memo'] = @target_factory_for['note']
    @target_factory_for['memorandum'] = @target_factory_for['note']
    @target_factory_for['event'] = @target_factory_for['appointment']
  end

end
