require 'targetstatevalues'

# Abstraction for the status of a STodoTarget
class TargetState
  include TargetStateValues

  public

  attr_reader :creation_time, :value
  # The date/time the associated target was completed or canceled
  attr_reader :completion_time

  ###  Access

  def active?
    result = value != COMPLETED && value != CANCELED
  end

  def to_s
    result = value
    if value == COMPLETED || value == CANCELED then
      label = value == COMPLETED ? 'completed on' : 'canceled on'
      result += " (#{time_24hour(completion_time)})"
    end
    assert_invariant {invariant}
    result
  end

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
