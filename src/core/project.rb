require 'compositetask'

# Composite tasks of some importance
class Project < CompositeTask
  attr_reader :goal

  ###  Access

  def to_s_appendix
    super + "#{GOAL_KEY}: #{goal}\n"
  end

  ###  Status report

  def spec_type; "project" end

  def formal_type
    self.class
  end

  private

  def set_fields spec
    super spec
    if spec.goal != nil then
      @goal = spec.goal
    end
  end

  ### Hook routine implementations

  def current_message_subject
    "project notification: #{handle}"
  end

  def current_message
    result = super + "goal: #{goal}\n"
  end

  def description_appendix
    "goal: #{goal}"
  end

  ###  Persistence

  def marshal_dump
    result = super
    result.merge!({
      'goal' => goal,
    })
    result
  end

  def marshal_load(data)
    super(data)
    @goal = data['goal']
  end

end
