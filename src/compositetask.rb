require_relative 'task'

# Tasks that contain one or more subtasks
class CompositeTask < Task
  attr_reader :tasks

  def initialize spec
    @tasks = []
    super spec
  end

  public

  def add_task(t)
    @tasks << t
  end
end
