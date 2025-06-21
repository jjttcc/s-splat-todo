
# Logic for deletion of a STodoTarget
module DeletionLogic

  protected

  attr_reader   :deleted_target

  # If 'handle' is not in the database, deleted_target will be nil.
  def perform_deletion(target, recursive, target_table, force = false)
    @deleted_target = nil
    begin
      if ! target.nil? then
        @deleted_target = target   #!!!!Deal with recursion???
        if recursive then
          target.children.each do |c|
            self.change_occurred = false  # (ensure precondition)
            perform_deletion(target_table[c.handle], recursive, target_table,
                             force)
          end
        end
        if target.parent_handle != nil then
          # "disown" the parent.
          parent = target_table[target.parent_handle]
          if parent and parent.can_have_children? then
            parent.remove_child(target)
          end
        end
        if ! recursive then
          target.children.each do |c|
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
    target_table.delete(target.handle)
  end

end
