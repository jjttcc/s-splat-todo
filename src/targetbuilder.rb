require_relative 'project'
require_relative 'scheduledevent'
require_relative 'memorandum'

# Builder of s*todo target objects
class TargetBuilder
  include SpecTools

  # All targets built from specs: Hash[handle -> STodoTarget]
  attr_reader :targets
  attr_reader :spec_collector

  public

  def specs
    @spec_collector.specs
  end

  private

  def initialize spec_collector
    @targets = []
    @spec_collector = spec_collector
    for s in self.specs do
      t = target_for(s)
      if t != nil then
        @targets << t
      else
        $log.debug "nil target for spec: #{s.inspect}"
      end
    end
  end

  def target_for spec
    result = nil
    builder = @@target_factory_for[spec.type]
    if builder == nil then
      warning = "Invalid type for spec - title: \"#{spec.title}\" " +
        "type: #{spec.type}"
      $log.warn warning
    else
      # Build the "target".
      t = builder.call(spec)
      if t.valid? then
        result = t
      end
    end
    result
  end

  @@target_factory_for = {
    'project' => lambda do |spec| Project.new(spec) end,
    'action' => lambda do |spec| CompositeTask.new(spec) end,
    'note' => lambda do |spec| Memorandum.new(spec) end,
    'appointment' => lambda do |spec| ScheduledEvent.new(spec) end,
  }
  # Define "type" aliases.
  @@target_factory_for['task'] = @@target_factory_for['action']
  @@target_factory_for['memo'] = @@target_factory_for['note']
  @@target_factory_for['memorandum'] = @@target_factory_for['note']
  @@target_factory_for['event'] = @@target_factory_for['appointment']
end
