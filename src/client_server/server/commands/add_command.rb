require 'work_command'

#!!!!See NOTE in WorkCommand!!!
class AddCommand < WorkCommand
  public

  def do_execute(the_caller)
logf = File.new("/tmp/addcmd#{$$}", "w")
logf.puts("#{self.class} self: #{self}")
logf.flush
    # strip out the 'command: add'
    opt_args = request.arguments[1 .. -1]
logf.puts("opt_args: #{opt_args}")
    options = TemplateOptions.new(opt_args, true)
logf.puts("options: #{options.inspect}")
logf.flush
    manager.target_builder.spec_collector = options
    manager.target_builder.set_create_mode
    manager.add_new_targets
logf.puts("#{self.class} ended")
logf.flush
  end

end
