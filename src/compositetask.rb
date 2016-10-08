require_relative 'task'

# Tasks that contain one or more subtasks
class CompositeTask < Task
  attr_reader :tasks

  def set_fields spec
    super spec
    @tasks = []
  end

  public

  def add_task(t)
    @tasks << t
  end
end
