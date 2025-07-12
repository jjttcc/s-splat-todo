class ClearDescendantsCommand < WorkCommand
  include CommandConstants, Contracts::DSL

  CLEAR_D_SEPARATOR = ':'

  def do_execute(the_caller)
    handle_spec = arg1
    hspec_components = handle_spec.split(/#{CLEAR_D_SEPARATOR}/)
    handle = hspec_components[0]
    exceptions = hspec_components[1 .. -1]
    target = database[handle]
    if target != nil then
      orig_descs = target.descendants
      orig_desc_count = orig_descs.count
      target.remove_descendants(exceptions)
      delete_list = orig_descs - target.descendants
      delete_list.each do |d|
        database.delete(d.handle)
      end
      git_commit(target)
      self.execution_succeeded = true
    end
  end

end
