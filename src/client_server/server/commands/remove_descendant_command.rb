require 'work_command'

class RemoveDescendantCommand < WorkCommand
  include CommandConstants, Contracts::DSL

  def do_execute(the_caller)
    ancestor_h = arg1
    descendant_h = arg2
    ancestor = database[ancestor_h]
    if ! ancestor.nil? then
      ancestor.remove_descendant(descendant_h)
      if ! ancestor.last_removed_descendant.nil? then
        removed_item = ancestor.last_removed_descendant
        database.delete(removed_item.handle)
        ancestor.clear_last_removed_descendant
        self.execution_succeeded = true
        git_commit(ancestor)
      end
    else
      self.response = "Ancestor for handle #{ancestor_h} not found."
    end
  end

end
