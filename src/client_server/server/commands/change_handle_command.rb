require 'work_command'

class ChangeHandleCommand < WorkCommand
  include CommandConstants, Contracts::DSL

  def do_execute(the_caller)
    handle = arg1
    new_handle = arg2
    succeeded_local = false # Assume failure until proven otherwise
    if handle.nil? || handle.empty? then
      self.response = "Original handle cannot be empty."
    elsif new_handle.nil? || new_handle.empty? then
      self.response = "New handle cannot be empty."
    elsif handle == new_handle then
      self.response = "New handle cannot be the same as the old handle."
    else
      target = database[handle]
      if target.nil? then
        self.response = "No item with handle '#{handle}' found."
      else
        begin
          # Attempt to delete the old entry
          database.delete(handle)
          target.change_handle(new_handle)
          database.store_target(target)
          git_commit(target)
          succeeded_local = true # All steps completed successfully
        rescue
          ### NOTE: This is not good enough - i.e., which of the above
          # operations failed and what should be reported? Should we do
          # some kind of rollback?
          self.response = "Failed to delete old entry for handle '#{handle}'."
        end
      end
    end

    self.execution_succeeded = succeeded_local
  end

end
