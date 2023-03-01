require 'templatetargetbuilder'
require 'stubbedspec'

# Editor of "template" s*todo target objects
class TargetEditor < TemplateTargetBuilder

  private

  def builder_key spec
    EDIT
  end

end
