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
          target.modify_fields(spec, database)
        else
          $log.debug "target with handle #{spec.handle} NOT found"
          self.execution_succeeded = false
          self.fail_msg = "No item with handle '#{spec.handle}' found."
        end
        git_commit(target)
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

end
