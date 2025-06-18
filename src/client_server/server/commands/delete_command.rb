require 'work_command'
require 'deletion_logic'

# Command to delete one STodoTarget
class DeleteCommand < WorkCommand
  include DeletionLogic

  public

  def do_execute(the_caller)
    args = request.arguments[1 .. -1]
    handle = handles_from_args(args)[0]
    if database.has_key?(handle) then
      cmd = request.command
      opts = opts_from_args(args)
      cmdopts = CommandOptions.new(:delete_target.to_s, opts)
      recursive = cmdopts.recursive?
      self.commit_message = cmdopts.message
      perform_deletion(handle, recursive, database, cmdopts.force?)
      if ! deleted_target.nil? then
        git_commit(deleted_target, opts)
      end
    else
      self.execution_succeeded = false
      self.fail_msg = "'#{handle}' is not the handle of an existing item."
    end
  end

#!!!refactor to use parent 'git_commit':
  def git_commit(target, opts)
    if target.commit then
      msg = target.commit
      i = opts.index(MSG_OPT)
      if ! opts[i+1].nil? then
        msg = opts[i+1]
      end
      repo = config.stodo_git
      repo.update_item(target)
      repo.commit msg
    end
  end

  private

  OPT_CHAR = '-'
  MSG_OPT  = '-m'

#!!!Need to move these two methods into a utility class/module:
  def opts_from_args arguments
    result = []
    i = 0
    while i < arguments.count do
      if arguments[i] =~ /^#{OPT_CHAR}/ then
        result << arguments[i]
        if arguments[i] == MSG_OPT then
          i = i + 1
          result << arguments[i]
        end
      end
      i = i + 1
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
