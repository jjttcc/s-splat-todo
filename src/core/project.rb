require 'task'

# Tasks that are important enough to have a goal
class Project < Task
  attr_reader :goal

  ###  Access

  def to_s_appendix
    result = super + "#{GOAL_KEY}: #{goal}\n"
    result
  end

  ###  Status report

  def spec_type; PROJECT end

  def formal_type
    self.class
  end

  private

  def main_modify_fields spec, orig_parent
    super spec, orig_parent
    @goal = spec.goal if spec.goal
  end

  def set_fields spec
    super spec
    if spec.goal != nil then
      @goal = spec.goal
    end
  end

  ### Hook routine implementations

  def current_message
    result = super + "\ngoal: #{goal}\n"
  end

  def description_appendix
    "goal: #{goal}"
  end

end
