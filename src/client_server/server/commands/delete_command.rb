require 'work_command'

#!!!!See NOTE in WorkCommand!!!
class DeleteCommand < WorkCommand
  public

  def do_execute(the_caller)
    args = request.arguments[1 .. -1]
    cmd = request.command
    opts = opts_from_args(args)
    handles = handles_from_args(args)
    handles.each do |h|
      if ! opts.empty? then
        manager.edit_target(h, cmd, opts)
      else
        manager.edit_target(h, cmd)
      end
    end
    manager.close_edit
  end

  private

  OPT_CHAR = '-'

#!!!Need to move these two methods into a utility class/module:
  def opts_from_args arguments
    result = []
    (0 .. arguments.count - 1).each do |i|
      if arguments[i] =~ /^#{OPT_CHAR}/ then
        result << arguments[i]
      end
    end
    if result.count > 0 then
      result.each do |e|
        arguments.delete(e)
      end
    end
    result
  end

  # handles from 'arguments' - everything up to, but not including, the
  # first occurrence of OPT_CHAR
  def handles_from_args arguments
    result = []
    arguments.each do |a|
      if a =~ /^#{OPT_CHAR}/ then
        break
      else
        result << a
      end
    end
    result
  end

end
