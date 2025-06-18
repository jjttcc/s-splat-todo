require 'work_command'

#!!!!See NOTE in WorkCommand!!!
class ChangeCommand < WorkCommand
  include CommandConstants, Contracts::DSL

  def do_execute(the_caller)
    # strip out the command:
    opt_args = request.arguments[1 .. -1]
    handle = opt_args[0]
    opt_args.unshift '-h'
    opt_args.unshift SpecTools::EDIT   # (the 'type' argument)
    options = TemplateOptions.new(opt_args, true)
#!!!to-do: Replace these 3 commands with equivalent code:
    manager.target_builder.spec_collector = options
    manager.target_builder.set_edit_mode
    manager.update_targets(options)
  end

end
