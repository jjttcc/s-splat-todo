require 'ruby_contracts'
require 'targetstatevalues'

module StateChangeFacilities
  include TargetStateValues
  include Contracts::DSL

  attr_reader :state_ch_error_msg

  # state change commands
  CANCEL, RESUME, FINISH, SUSPEND = 'cancel', 'resume', 'finish', 'suspend'

  # Execute a "guarded" state-change - i.e., iff 'statechg' is valid,
  # execute the change.
  # Return whether or not the specified change was valid/executed.
  post 'return boolean' do |result|
    ! result.nil? && [true, false].include?(result)
  end
  def execute_guarded_state_change(target, statechg)
      current_state = target.state
      old_state = current_state.value
      valid = false
      case statechg
      when FINISH
        if IN_PROGRESS == old_state then
          current_state.send(statechg); valid = true
        end
      when RESUME
        if SUSPENDED == old_state then
          current_state.send(statechg); valid = true
        end
      when CANCEL
        if
          [IN_PROGRESS,
           SUSPENDED].include?(old_state)
        then
          current_state.send(statechg); valid = true
        end
      when SUSPEND
        if IN_PROGRESS == old_state then
          current_state.send(statechg); valid = true
        end
      end
      if not valid then
        @state_ch_error_msg =
          "Invalid state change request: #{old_state} => #{statechg}"
      end
      valid
  end

end
