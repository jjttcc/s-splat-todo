=begin
Notes on new TargetState class:
  X It has a creation date/time (time the Target was created).
  X It defaults to "in-progress" when created.
  X Other states: canceled, completed, suspended.
  X When it's canceled or changed to completed, an "end time" (better
    name?) is created to be associated with the state change; in other
    words, this gives the time the target was canceled ("cancellation
    date") or that it was completed ("completion date").
  X It has a query: 'value', which gives the value or name of the state,
    which will be one of a set of constants (IN_PROGRESS, COMPLETED, ...).
=end
module StateValues
  include ErrorTools, TimeTools

  public

  IN_PROGRESS, SUSPENDED, CANCELED, COMPLETED =
  'in-progress', 'suspended', 'canceled', 'completed'
end

# Abstraction for the status of a STodoTarget
class TargetState
  include StateValues

  public

  attr_reader :creation_time, :value
  # The date/time the associated target was completed or canceled
  attr_reader :completion_time

  ## State transitions

  # Set 'value' to CANCELED.
  def cancel
    assert_precondition('value == IN_PROGRESS || value == SUSPENDED') {
      value == IN_PROGRESS || value == SUSPENDED
    }
    @value = CANCELED
    @completion_time = Time.now
    assert_postcondition('value == CANCELED') {value == CANCELED}
    assert_invariant {invariant}
  end

  # Set 'value' to COMPLETED.
  def finish
    assert_precondition('value == IN_PROGRESS') {
      value == IN_PROGRESS
    }
    @value = COMPLETED
    @completion_time = Time.now
    assert_postcondition('value == COMPLETED') {value == COMPLETED}
    assert_invariant {invariant}
  end

  # Set 'value' to SUSPENDED.
  def suspend
    assert_precondition('value == IN_PROGRESS') {
      value == IN_PROGRESS
    }
    @value = SUSPENDED
    assert_postcondition('value == SUSPENDED') {value == SUSPENDED}
    assert_invariant {invariant}
  end

  # Set 'value' from SUSPENDED to IN_PROGRESS.
  def resume
    assert_precondition('value == SUSPENDED') {
      value == SUSPENDED
    }
    @value = IN_PROGRESS
    assert_postcondition('value == IN_PROGRESS') {value == IN_PROGRESS}
    assert_invariant {invariant}
  end

  ###  Access

  def to_s
    result = value
    if value == COMPLETED || value == CANCELED then
      label = value == COMPLETED ? 'completed on' : 'canceled on'
      result += " (#{time_24hour(completion_time)})"
    end
    assert_invariant {invariant}
    result
  end

  ### class invariant

  def invariant
    implies(value==IN_PROGRESS || value==SUSPENDED, completion_time==nil) &&
    implies(value==COMPLETED || value==CANCELED, completion_time!=nil) &&
    ([IN_PROGRESS, SUSPENDED, CANCELED, COMPLETED].include? value)
  end

  private

  def initialize
    @creation_time = Time.now
    @value = IN_PROGRESS
    @completion_time = nil
    assert_invariant {invariant}
  end
end
