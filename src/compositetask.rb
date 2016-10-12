require_relative 'task'

# Tasks that contain one or more subtasks
class CompositeTask < Task
  attr_reader :tasks

  public

  def add_task(t)
    @tasks << t
  end

  private

  def set_fields spec
    super spec
    @tasks = []
  end
end
