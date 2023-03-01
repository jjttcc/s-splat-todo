require 'targetbuilder'
require 'stubbedspec'

# Builder of "template" s*todo target objects
class TemplateTargetBuilder < TargetBuilder

  public

  def prepare_targets
    self.targets = []
    t = target_for(spec)
$log.warn "[TTB::prepare_targets] spec.class: #{spec.class}"
$log.warn "[TTB::prepare_targets] spec: #{spec}"
$log.warn "[TTB::prepare_targets] t: #{t.class}"
    if t != nil then
$log.warn "[TTB::prepare_targets] t: #{t.handle}"
      self.targets << t
    end
  end

  private

  attr_accessor :spec

  def initialize options, the_existing_targets = nil
    self.existing_targets = the_existing_targets
    self.spec = StubbedSpec.new options
    super nil
  end

end
