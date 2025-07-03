require 'work_command'
require 'stodo_target_constants'

class ChangeCommand < WorkCommand
  include CommandConstants, STodoTargetConstants, SpecTools, Contracts::DSL

  def do_execute(the_caller)
    args = request.arguments[1 .. -1]
    args.unshift '-h'
    args.unshift EDIT   # (the 'type' argument)
    spec = new_spec(args)
    if ! spec.nil? then
      if spec.handle then
        target = database[spec.handle]
        if target then
          $log.debug "#{target.handle} found"
          if spec.parent_handle then
            change_parent(target, spec)
          end
          if execution_succeeded then
            # Set parent to nil in the spec to avoid the bug in
            # modify_fields, which would otherwise incorrectly process it.
            spec.override_setting(:parent, nil)
            target.modify_fields(spec, database)
            git_commit(target)
          end
        else
          $log.debug "target with handle #{spec.handle} NOT found"
          self.execution_succeeded = false
          self.fail_msg = "No item with handle '#{spec.handle}' found."
        end
      else
        self.execution_succeeded = false
        self.fail_msg = "No handle in specification"
      end
    else
      self.execution_succeeded = false
      self.fail_msg = spec_error
    end
  end

  def valid_type(type)
    type == EDIT
  end

  private

=begin
Note: change_parent, below, was written by gemini-cli when I asked it
to fix problems documented in comments in the previous version of this
file using STodoTargetEditor.change_parent as a guide. It needs to
be tested and cleaned up a bit. (It also made some changes to
'do_execute'.)

Here is a summary gemini-cli gave of its changes.
(Slightly out of date: gemini implemented a small fix re call of modify_fields)
✦ I have integrated the logic from STodoTargetEditor into change_command.rb.
Here's a summary of the changes:

   * The do_execute method now checks if a parent_handle is part of the
     specification.
       * If it is, it calls the new change_parent method.
       * Otherwise, it calls the original target.modify_fields for other
         types of changes.
   * The new private method change_parent contains the robust logic from the
     legacy file. It correctly handles:
       * Parent Removal: It disconnects the item from its old parent.
       * Orphaning: It correctly sets the parent_handle to nil when the user
         specifies {none}.
       * Invalid Parent: It sets a failure message if the new parent handle
         is invalid.
=end

  def change_parent(target, spec)
    new_parent_handle = spec.parent_handle
    make_orphan = new_parent_handle.downcase == NO_PARENT
    if make_orphan then
      new_parent = nil
    else
      new_parent = database[new_parent_handle]
    end
    if ! make_orphan && new_parent.nil? then
      self.execution_succeeded = false
      self.fail_msg = "Invalid parent handle '#{new_parent_handle}'"
      return
    end
    if target.parent_handle then
      old_parent = database[target.parent_handle]
      if old_parent then
        old_parent.remove_child(target)
      end
    end
    if make_orphan then
      target.parent_handle = nil
    else
      target.parent_handle = new_parent.handle
      new_parent.add_child(target)
    end
  end

end
