require 'work_command'

class CloneCommand < WorkCommand
  include CommandConstants, Contracts::DSL

  def do_execute(the_caller)
    handle = arg1
    new_handle = arg2
    if database[new_handle].nil? then
      target = database[handle]
      clone = target.clone
      # Guaranteed by 'clone':
      check(:same_parent) { clone.parent_handle == target.parent_handle }
      clone.handle = new_handle
      # (Call 'force_update' instead of store_target(clone) to ensure that
      #  clone.prepare_for_db_write is called to prevent Oj nesting error.)
      clone.force_update
      if ! target.parent_handle.nil? then
        parent = database[target.parent_handle]
        parent.add_child(clone)
      end
      self.execution_succeeded = true
      git_commit(clone)
    else
      msg = "cloning error: handle #{new_handle} is already in use."
      $log.warn msg
      self.response = msg
    end
  end

end
