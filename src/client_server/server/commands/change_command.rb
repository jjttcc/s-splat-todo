require 'work_command'
require 'stodo_target_constants'

class ChangeCommand < WorkCommand
  include CommandConstants, STodoTargetConstants, SpecTools, Contracts::DSL

  private

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
          parent_change_failed = false
          if spec.parent then
            parent_change_failed = ! change_parent(target, spec)
          end
          if ! parent_change_failed then
            # Set parent to nil in the spec to avoid the bug in
            # modify_fields, which would otherwise incorrectly process it.
            spec.override_setting(:parent, nil)
            target.modify_fields(spec, database)
            git_commit(target)
            self.execution_succeeded = true
          end
        else
          $log.debug "target with handle #{spec.handle} NOT found"
          self.fail_msg = "No item with handle '#{spec.handle}' found."
        end
      else
        self.fail_msg = "No handle in specification"
      end
    else
      self.fail_msg = spec_error
    end
  end

  def valid_type(type)
    type == EDIT
  end

  private

  # Return boolean: false if the change fails; true otherwise.
  def change_parent(target, spec)
    result = true
    new_parent_handle = spec.parent
    make_orphan = new_parent_handle.downcase == NO_PARENT
    if make_orphan then
      new_parent = nil
    else
      new_parent = database[new_parent_handle]
    end
    if ! make_orphan && new_parent.nil? then
      result = false
      self.fail_msg = "Invalid parent handle '#{new_parent_handle}'"
    else
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
    result
  end

end
