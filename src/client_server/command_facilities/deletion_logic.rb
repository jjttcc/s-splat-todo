
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
    target_table.delete(handle)
  end

end
