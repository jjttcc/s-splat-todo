
# Logic for deletion of a STodoTarget
module DeletionLogic

  protected

  attr_accessor :commit_message
  attr_reader   :deleted_target

  # If 'handle' is not in the database, deleted_target will be nil.
  def perform_deletion(handle, recursive, target_table, force = false)
    @deleted_target = nil
    begin
      t = target_table[handle]
      if ! t.nil? then
        @deleted_target = t   #!!!!Deal with recursion???
        if recursive then
          t.children.each do |c|
            self.change_occurred = false  # (ensure precondition)
            perform_deletion(c.handle, recursive, target_table, force)
          end
        end
        if t.parent_handle != nil then
          # "disown" the parent.
          parent = target_table[t.parent_handle]
          if parent and parent.can_have_children? then
            parent.remove_child(t)
          end
        end
        if ! recursive then
          t.children.each do |c|
            # Make c into an orphan.
            c.parent_handle = nil
          end
        end
      end
    rescue Exception => e
      $log.warn e
      if ! force then
        raise e
      else
        # The "force" option was specified, so continue.
      end
    end
=begin
#!!!!What to do with this?:
    repo = Configuration.instance.stodo_git
    if ! t.nil? && repo.in_git(handle) then
      execute_git_command(@command_for[__method__], t)
    end
=end
    target_table.delete(handle)
  end

=begin
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
=end

end
