# Composite tasks of some importance
class Project < CompositeTask
  attr_reader :goal

  private

  def set_fields spec
    super spec
    if spec.goal != nil then
      @goal = spec.goal
    end
  end
end
