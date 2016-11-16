require 'targetbuilder'
require 'stubbedspec'

# Builder of "template" s*todo target objects
class TemplateTargetBuilder < TargetBuilder

  private

  def initialize type
    spec = StubbedSpec.new type
    init_target_factory
    @targets = []
    t = target_for(spec)
    if t != nil then
      @targets << t
    end
  end

end
