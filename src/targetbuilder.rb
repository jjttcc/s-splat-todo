require_relative 'project'

# Builder of s*todo target objects
class TargetBuilder
  include SpecTools

  attr_reader :targets

  private

  def initialize specs
    @targets = []
    for s in specs do
      t = target_for(s)
      if t != nil then
        @targets << t
      else
        $log.error "nil target for spec: #{s.inspect}"
      end
    end
puts "targets:\n=============================="
    for t in @targets do
      puts "#{t.class}, #{t.title}"
    end
puts "=============================="
  end

  def target_for spec
    result = nil
$log.error "spectype: #{spec.type}"
    builder = @@target_factory_for[spec.type]
    if builder == nil then
#$log.error "No builder for: #{spec.type}"
      $log.error "No builder for: #{spec.inspect}"
$stderr.puts '_' * 68
    else
      result = builder.call(spec)
    end
    result
  end

  @@target_factory_for = {
    'project' => lambda do |spec| Project.new(spec) end,
    'action' => lambda do |spec| CompositeTask.new(spec) end,
    'note' => lambda do |spec| Memorandum.new(spec) end,
  }
  @@target_factory_for['task'] = @@target_factory_for['action']
  @@target_factory_for['memo'] = @@target_factory_for['note']
  @@target_factory_for['memorandum'] = @@target_factory_for['note']
end
