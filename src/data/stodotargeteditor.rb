# Editors of "STodoTarget"s
class STodoTargetEditor

  public

  attr_reader :last_command_failed, :last_failure_message

  def apply_command(handle, raw_command)
    @last_command_failed = false
    clean_handle = handle.split(/#{DEFAULT_COMPONENT_SEPARATOR}/)[0]
    if @target_for[clean_handle] == nil then
      @last_command_failed = true
      @last_failure_message = "No target found with handle #{handle}."
    else
      components = cmd_and_args_for(handle, raw_command)
      command, args = components[0], components[1..-1]
      method = @method_for[command]
      if method == nil then
        @last_command_failed = true
        @last_failure_message = "Invalid command: #{command}."
      else
        self.send(method, *args)
      end
    end
  end

  private

  DEFAULT_COMPONENT_SEPARATOR = ":"
  private_constant :DEFAULT_COMPONENT_SEPARATOR

  def initialize(target_map)
    @target_for = target_map
    initialize_method_map
  end

  def initialize_method_map
    @method_for = {
      'delete' => :delete_target,
      'state' => :modify_state,
      'clear_descendants' => :clear_descendants,
    }
  end

  # array constructed from 'handle' and 'rawcmd' with the following structure:
  # result[0] is the first component from
  #    rawcmd.split(/#{DEFAULT_COMPONENT_SEPARATOR}/)
  # result[1] is 'handle'
  # result[2...] are the remaining components (if any) from
  #   rawcmd.split(/#{DEFAULT_COMPONENT_SEPARATOR}/)
  def cmd_and_args_for(handle, rawcmd)
    result = []
    command_parts = rawcmd.split(/#{DEFAULT_COMPONENT_SEPARATOR}/)
    result << command_parts[0]    # The command
    result << handle
    if command_parts.length > 1 then
      result.concat(command_parts[1..-1])
    end
    result
  end

  ### Methods for @method_for table

  # Delete the target IDd by 'handle'.
  def delete_target handle
    t = @target_for[handle]
    if t.parent_handle != nil then
      parent = @target_for[t.parent_handle]
      if parent and parent.can_have_children? then
        parent.remove_child(t)
      end
    end
  end

  # Clear (delete) all of the specified target's (via 'handle')
  # descendants.
  def clear_descendants handle_spec
    hspec_components = handle_spec.split(/#{DEFAULT_COMPONENT_SEPARATOR}/)
    handle = hspec_components[0]
    exceptions = hspec_components[1 .. -1]
    t = @target_for[handle]
    if t != nil then
      t.remove_descendants(exceptions)
    end
  end

  # state change commands
  CANCEL, RESUME, FINISH, SUSPEND = 'cancel', 'resume', 'finish', 'suspend'

  # Change the state of the target IDd by 'handle' to 'state'
  def modify_state handle, state
    t = @target_for[handle]
    if t != nil then
      execute_guarded_state_change(t, state)
    else
      $log.warn "Expected target for handle #{handle} not found."
    end
  end

  def execute_guarded_state_change(target, statechg)
      current_state = target.state
      old_state = current_state.value
      valid = false
      case statechg
      when FINISH
        if TargetStateValues::IN_PROGRESS == old_state then
          current_state.send(statechg); valid = true
        end
      when RESUME
        if TargetStateValues::SUSPENDED == old_state then
          current_state.send(statechg); valid = true
        end
      when CANCEL
        if
          [TargetStateValues::IN_PROGRESS,
           TargetStateValues::SUSPENDED].include?(old_state)
        then
          current_state.send(statechg); valid = true
        end
      when SUSPEND
        if TargetStateValues::IN_PROGRESS == old_state then
          current_state.send(statechg); valid = true
        end
      end
      if not valid then
        $log.warn "Invalid state change request: #{old_state} => #{statechg}"
      end
  end

end
