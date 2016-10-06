require_relative 'project'

# Builder of s*todo target objects
class TargetBuilder
  include SpecTools

  attr_reader :targets

  private

  def initialize specs
    @targets = []
    for s in specs do
      @targets << target_for(s)
    end
puts "targets:\n=============================="
    for t in @targets do
      p t
    end
puts "=============================="
  end

  def target_for spec
    builder = @@target_factory_for[spec.type]
    if builder == nil then
      # !!!!!Deal with invalid value - spec.type!!!!!
    else
      builder.call(spec)
    end
  end

  #!!!!!Consider moving this to a module:
  @@target_factory_for = {
    'project' => lambda do |spec| Project.new(spec) end,
    'action' => lambda do |spec| CompositeTask.new(spec) end,
    'note' => lambda do |spec| Memorandum.new(spec) end,
  }
  @@target_factory_for['task'] = @@target_factory_for['action']
  @@target_factory_for['memo'] = @@target_factory_for['note']
  @@target_factory_for['memorandum'] = @@target_factory_for['note']
end
