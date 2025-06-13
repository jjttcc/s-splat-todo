require 'work_command'

#!!!!See NOTE in WorkCommand!!!
class ChangeHandleCommand < WorkCommand
  include CommandConstants, Contracts::DSL

  def do_execute(the_caller)
    # strip out the command:
    opt_args = request.arguments[1 .. -1]
    handle = opt_args[0]
    command_and_args = [CH_HANDLE_CMD, opt_args[1]]
    manager.edit_target(handle, command_and_args)
    manager.close_edit
  end

end
