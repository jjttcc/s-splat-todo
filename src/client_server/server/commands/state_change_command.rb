require 'state_change_facilities'

class StateChangeCommand < WorkCommand
  include CommandConstants, StateChangeFacilities, Contracts::DSL

  def do_execute(the_caller)
    state = arg1
    handle = arg2
    target = nil
    if ! database.has_key?(handle) then
      msg = "No target found with handle #{handle}."
      $log.warn msg
      self.execution_succeeded = false
      self.response = msg
    else
      target = database[handle]
      if target != nil then
        succeeded = execute_guarded_state_change(target, state)
        if succeeded then
          target.force_update
          git_commit(target)
        else
          msg = "State change (of #{handle}) to #{state} failed."
          if ! state_ch_error_msg.nil? then
            msg = state_ch_error_msg
          end
          self.execution_succeeded = false
          self.response = msg
        end
      else
        msg = "Expected target for handle #{handle} not found."
        self.execution_succeeded = false
        self.response = msg
      end
    end
  end

end
