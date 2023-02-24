require 'ruby_contracts'
require 'targetstatevalues'

# Abstraction for the status of a STodoTarget
class TargetState
  include TargetStateValues
  include Contracts::DSL

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
    result
  end

  ## State transitions

  # Change state to CANCELED.
  pre 'value == IN_PROGRESS || value == SUSPENDED' do
    self.value == IN_PROGRESS || self.value == SUSPENDED
  end
  post 'value == CANCELED' do self.value == CANCELED end
  post 'invariant' do invariant end
  def cancel
    @value = CANCELED
    @completion_time = Time.now
  end

  # Change state to COMPLETED.
  pre 'value == IN_PROGRESS' do self.value == IN_PROGRESS end
  post 'value == COMPLETED' do self.value == COMPLETED end
  post 'invariant' do invariant end
  def finish
    @value = COMPLETED
    @completion_time = Time.now
  end

  # Change state to SUSPENDED.
  pre 'value == IN_PROGRESS' do self.value == IN_PROGRESS end
  post 'value == SUSPENDED' do self.value == SUSPENDED end
  post 'invariant' do invariant end
  def suspend
    @value = SUSPENDED
  end

  # Change state from SUSPENDED to IN_PROGRESS.
  pre 'value == SUSPENDED' do value == SUSPENDED end
  post 'value == IN_PROGRESS' do self.value == IN_PROGRESS end
  post 'invariant' do invariant end
  def resume
    @value = IN_PROGRESS
  end

  ### class invariant

  def invariant
    implies(value==IN_PROGRESS || value==SUSPENDED, completion_time==nil) &&
    implies(value==COMPLETED || value==CANCELED, completion_time!=nil) &&
    ([IN_PROGRESS, SUSPENDED, CANCELED, COMPLETED].include? value)
  end

  private

  post 'invariant' do invariant end
  def initialize
    @creation_time = Time.now
    @value = IN_PROGRESS
    @completion_time = nil
  end
end
