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
    elsif ! database[new_handle].nil? then
      self.response =
        "New handle cannot the handle of an existing item."
    else
      target = database[handle]
      if target.nil? then
        self.response = "No item with handle '#{handle}' found."
      else
        begin
          database.delete(handle)
          target.change_handle(new_handle)
          # "Force" the update to ensure unwanted attributes are emptied.
          target.force_update
          git_commit(target)
          succeeded_local = true # All steps completed successfully
        rescue Exception => e
          $log.error "Error during change_handle operation: #{e.message}"
          $log.error e.backtrace.join("\n")
          self.response = "Failed to delete old entry for handle '#{handle}'."
        end
      end
    end
    self.execution_succeeded = succeeded_local
  end

end
