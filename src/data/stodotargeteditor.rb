# Editors of "STodoTarget"s
class STodoTargetEditor
  include SpecTools, ErrorTools

  public

  attr_reader :last_command_failed, :last_failure_message

  def apply_command(handle, parameters)
    @last_command_failed = false
    clean_handle = handle.split(/#{DEFAULT_COMPONENT_SEPARATOR}/)[0]
    if @target_for[clean_handle] == nil then
      @last_command_failed = true
      @last_failure_message = "No target found with handle #{handle}."
    else
      if parameters.is_a?(Enumerable) then
        command, args = parameters[0], [handle, parameters[1..-1]].flatten
      else
        components = cmd_and_args_for(handle, parameters)
        command, args = components[0], components[1..-1]
      end
      method = @method_for[command]
      if method == nil then
        @last_command_failed = true
        @last_failure_message = "Invalid command: #{command}."
      else
        self.send(method, *args)
      end
    end
  end

  protected

  attr_reader :target_for

  private

  DEFAULT_COMPONENT_SEPARATOR, NO_PARENT = ":", '{none}'
  private_constant :DEFAULT_COMPONENT_SEPARATOR, :NO_PARENT

  def initialize(target_map)
    @target_for = target_map
    initialize_method_map
  end

  def initialize_method_map
    @method_for = {
      'delete' => :delete_target,
      'change_parent' => :change_parent,
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
  def cmd_and_args_for(handle, params)
    result = []
    command_parts = params.split(/#{DEFAULT_COMPONENT_SEPARATOR}/)
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
    assert_precondition("target for #{handle} exists") {
      ! self.target_for[handle].nil?
    }
    t = self.target_for[handle]
    if t.parent_handle != nil then
      parent = self.target_for[t.parent_handle]
      if parent and parent.can_have_children? then
        parent.remove_child(t)
      end
    end
  end

  # Change parent of item with handle 'handle' to item with handle 'phandle'.
  # If 'phandle' is empty, the item identified by 'handle' is changed to be
  # parentless, i.e., a top-level ancestor.
  #fix!!!: when handle/item has no parent, the request is not fulfilled.
  #fix!!!: Don't fulfill a request to make one's child into one's parent -
  #        i.e., to make handle/item and phandle/item each other's parent
  #        and children at the same time.
=begin
########## doc changes in progress...:
  # Note: If the item with handle 'phandle' is a child of

  # Change parent of item with handle 'handle' to item with handle 'phandle'.
  # If 'phandle' is empty, the item identified by 'handle' is changed to be
=end
  # postcondition: ! self.target_for[phandle].nil? implies
  #     'self.target_for[self.target_for[handle].parent_handle] ==
  #     self.target_for[phandle]')
  def change_parent handle, phandle
    assert_precondition("target for #{handle} exists") {
      ! self.target_for[handle].nil?
    }
    assert_precondition("phandle exists") { ! phandle.nil?  }
    t = self.target_for[handle]
    make_orphan = ! phandle.nil? && phandle.downcase == NO_PARENT
    new_parent = self.target_for[phandle]
    if ! make_orphan && new_parent.nil? then
        $log.warn(invalid_parent_handle_msg(handle, phandle))
    else
      if t.parent_handle != nil then
        old_parent = @target_for[t.parent_handle]
        if old_parent and old_parent.can_have_children? then
          old_parent.remove_child(t)
        end
        if make_orphan then
          t.parent_handle = nil
        else
          assert('new parent exists') { ! new_parent.nil? }
          assert('consistent handle values') { phandle == new_parent.handle }
          t.parent_handle = new_parent.handle
          new_parent.add_child(t)
        end
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
