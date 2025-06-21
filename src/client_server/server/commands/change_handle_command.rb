require 'work_command'

#!!!!See NOTE in WorkCommand!!!
class ChangeHandleCommand < WorkCommand
  include CommandConstants, Contracts::DSL

  def do_execute(the_caller)
    handle = arg1
    new_handle = arg2
    target = database[handle]
    # Remove the old entry/target, associated with the old 'handle' key:
    database.delete(handle)
    target.change_handle(new_handle)
    # Store the 'target' again, with a new handle:
    database.store_target(target)
    git_commit(target)
  end

end
