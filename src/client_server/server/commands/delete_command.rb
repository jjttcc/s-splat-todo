require 'work_command'
require 'deletion_logic'

# Command to delete one STodoTarget
class DeleteCommand < WorkCommand
  include DeletionLogic

  public

  def do_execute(the_caller)
    handle = arg1
    target = database[handle]
    if ! target.nil? then
      perform_deletion(target, recursive, database, force)
      if ! deleted_target.nil? then
        git_commit(deleted_target)
      end
    else
      self.execution_succeeded = false
      self.fail_msg = "'#{handle}' is not the handle of an existing item."
    end
  end

end
