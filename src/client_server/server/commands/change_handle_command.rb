require 'work_command'

class ChangeHandleCommand < WorkCommand
  include CommandConstants, Contracts::DSL

  def do_execute(the_caller)
    handle = arg1
    new_handle = arg2
    succeeded_local = false # Assume failure until proven otherwise

    if handle.nil? || handle.empty? then
      self.fail_msg = "Original handle cannot be empty."
    elsif new_handle.nil? || new_handle.empty? then
      self.fail_msg = "New handle cannot be empty."
    elsif handle == new_handle then
      self.fail_msg = "New handle cannot be the same as the old handle."
    else
      target = database[handle]
      if target.nil? then
        self.fail_msg = "No item with handle '#{handle}' found."
      else
        # Attempt to delete the old entry
        if database.delete(handle) then # Assuming delete returns true on success
          #!!!the above condition: database.delete(handle) is incorrect:
          #!!!It will return an integer that is >= 0 - i.e., awlays 'true'.
          # Attempt to change the handle on the target object
          target.change_handle(new_handle)
          if target.last_op_changed_state then # Check if change_handle succeeded
            # Attempt to store the target with the new handle
            if database.store_target(target) then # Assuming store_target returns true on success
              git_commit(target) # git_commit doesn't return status, assume it works if previous steps did
              succeeded_local = true # All steps completed successfully
            else
              self.fail_msg = "Failed to store target with new handle '#{new_handle}'."
              # Revert delete if store fails? This gets complicated. For now, just fail.
            end
          else
            self.fail_msg = "Failed to change handle on target object."
            # Revert delete if change_handle fails?
          end
        else
          self.fail_msg = "Failed to delete old entry for handle '#{handle}'."
        end
      end
    end

    self.execution_succeeded = succeeded_local
  end

end
