require 'targetbuilder'
require 'stubbedspec'

# Builder of "template" s*todo target objects
class TemplateTargetBuilder < TargetBuilder

  private

  def previous__initialize options
    spec = StubbedSpec.new options
    init_target_factory
    @targets = []
    t = target_for(spec)
    if t != nil then
      @targets << t
    end
  end

#!!![new version]:
  def initialize options, tmp_exist_tgts = nil
    self.existing_targets = tmp_exist_tgts
    spec = StubbedSpec.new options
    super nil
    @targets = []
    t = target_for(spec)
    if t != nil then
      @targets << t
    end
  end
#!!![end new version!!!]

  def work_initialize_v1 options,
#!!!:
tmp_exit_tgts = nil
self.existing_targets = tmp_exit_tgts
@time_changed_for = {}
#!!![end newstuff!!!]
    spec = StubbedSpec.new options
    init_target_factory
    @targets = []
    t = target_for(spec)
    if t != nil then
      @targets << t
    end
  end

end
