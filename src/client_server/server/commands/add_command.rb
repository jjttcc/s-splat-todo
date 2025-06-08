require 'work_command'

class AddCommand < WorkCommand
  public

  def execute(request)
    # strip out the 'command: add'
    opt_args = request.arguments[1 .. -1]
    options = TemplateOptions.new(opt_args, true)
    manager.target_builder.spec_collector = options
    manager.add_new_targets
  end

end
