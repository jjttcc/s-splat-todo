require 'task'

# Tasks that are important enough to have a goal
class Project < Task
  attr_reader :goal

  ###  Access

  def to_s_appendix
    super + "#{GOAL_KEY}: #{goal}\n"
  end

  ###  Status report

  def spec_type; PROJECT end

  def formal_type
    self.class
  end

  ###  Element change

  def modify_fields spec
    super spec
    @goal = spec.goal if spec.goal
  end

  private

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
