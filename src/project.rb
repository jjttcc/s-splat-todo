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

  ### Hook routine implementations

  def email_subject
    "project notification: #{handle}" + subject_suffix
  end

  def email_body
    result = super + "goal: #{goal}\n"
  end

  def description_appendix
    "goal: #{goal}"
  end

end
