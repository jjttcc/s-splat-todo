require_relative 'task'

# Composite tasks of some importance
class Project < CompositeTask
  attr_reader :goal

  def initialize spec
    @tasks = []
    super spec
    if spec.goal != nil then
      @goal = spec.goal
    end
  end
end
