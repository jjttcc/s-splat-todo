require 'work_command'

class ChangeCommand < WorkCommand
  include CommandConstants, Contracts::DSL

  def execute(request)
    # strip out the command:
    opt_args = request.arguments[1 .. -1]
    handle = opt_args[0]
    opt_args.unshift '-h'
    opt_args.unshift SpecTools::EDIT   # (the 'type' argument)
    options = TemplateOptions.new(opt_args, true)
    manager.target_builder.spec_collector = options
    manager.target_builder.set_edit_mode
    manager.update_targets(options)
  end

end
