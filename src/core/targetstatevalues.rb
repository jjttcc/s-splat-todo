module TargetStateValues
  include ErrorTools, TimeTools

  public

  IN_PROGRESS, SUSPENDED, CANCELED, COMPLETED =
  'in-progress', 'suspended', 'canceled', 'completed'

  def all_state_values
    [IN_PROGRESS, SUSPENDED, CANCELED, COMPLETED]
  end

end
