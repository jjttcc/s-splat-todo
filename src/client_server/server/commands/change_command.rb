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
        t = database[spec.handle]
        if t then
          $log.debug "#{t.handle} found"
          t.modify_fields(spec, database)
        else
          $log.debug "t NOT found"
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

end
