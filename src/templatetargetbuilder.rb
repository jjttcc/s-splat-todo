require_relative 'targetbuilder'
require_relative 'stubbedspec'

# Builder of "template" s*todo target objects
class TemplateTargetBuilder < TargetBuilder

  private

  def initialize type
    spec = StubbedSpec.new type
    @targets = [target_for(spec)]
  end

end
