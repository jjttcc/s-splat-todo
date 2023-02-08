# Editors of "STodoTarget"s
class STodoTargetEditor
  include SpecTools, ErrorTools

  public

  attr_reader :last_command_failed, :last_failure_message,
    # Did the last editor command result in a state change that
    # requires a database update?:
    :change_occurred

  def apply_command(handle, parameters)
    @last_command_failed = false
    self.change_occurred = false
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

  attr_writer :change_occurred

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
    assert_precondition("No data change yet") {
      self.change_occurred == false
    }
    assert_precondition("target for #{handle} exists") {
      ! self.target_for[handle].nil?
    }
    t = self.target_for[handle]
    if t.parent_handle != nil then
      # "disown" the parent.
      parent = self.target_for[t.parent_handle]
      if parent and parent.can_have_children? then
        parent.remove_child(t)
      end
    end
    t.children.each do |c|
      # Make c into an orphan.
      c.parent_handle = nil
    end
    self.target_for.delete(t.handle)
    self.change_occurred = true
  end

  # Change parent of item with handle 'handle' to item with handle 'phandle'.
  # If 'phandle' is empty, the item identified by 'handle' is changed to be
  # parentless, i.e., a top-level ancestor.
  # Note: If the item with handle 'phandle' is a child of the item with
  # 'handle' - i.e., the request is to make the child (phandle) the parent
  # of its own parent (handle), this recursive relationship is not created
  # and a warning message to that effect is logged.
  def change_parent handle, phandle
    assert_precondition("No data change yet") {
      self.change_occurred == false
    }
    assert_precondition("target for #{handle} exists") {
      ! self.target_for[handle].nil?
    }
    assert_precondition("phandle exists") { ! phandle.nil?  }
    t = self.target_for[handle]
    new_parent = nil
    make_orphan = ! phandle.nil? && phandle.downcase == NO_PARENT
    if ! make_orphan then
      new_parent = self.target_for[phandle]
    end
    if ! new_parent.nil? && t == new_parent then
      $log.warn(request_to_make_self_parent_msg(handle, phandle))
    elsif ! make_orphan && new_parent.nil? then
      $log.warn(invalid_parent_handle_msg(handle, phandle))
    else
      if ! make_orphan && t.is_parent?(new_parent) then
        $log.warn(recursive_child_parent_msg(handle, phandle))
      else
        if t.parent_handle != nil then
          # "Discard" the old parent.
          old_parent = @target_for[t.parent_handle]
          if old_parent and old_parent.can_have_children? then
            old_parent.remove_child(t)
          end
        end
        if make_orphan then
          t.parent_handle = nil
        else
          assert('new parent exists') { ! new_parent.nil? }
          assert('consistent handle values') { phandle == new_parent.handle }
          t.parent_handle = new_parent.handle
          new_parent.add_child(t)
        end
        self.change_occurred = true
      end
    end
  end

  def change_parent_work1 handle, phandle
    assert_precondition("target for #{handle} exists") {
      ! self.target_for[handle].nil?
    }
    assert_precondition("phandle exists") { ! phandle.nil?  }
    t = self.target_for[handle]
    make_orphan = ! phandle.nil? && phandle.downcase == NO_PARENT
    recursive_request = false
    new_parent = self.target_for[phandle]
    if ! make_orphan && new_parent.nil? then
      $log.warn(invalid_parent_handle_msg(handle, phandle))
    else
      if t.parent_handle != nil then
        # "Discard" the old parent.
        old_parent = @target_for[t.parent_handle]
        if old_parent then
          if t.is_parent?(old_parent) then
            $log.warn(recursive_child_parent_msg(handle, phandle))
            recursive_request = true
          else
            if old_parent.can_have_children? then
              old_parent.remove_child(t)
            end
          end
        end
      end
      if ! recursive_request then
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
    assert_precondition("No data change yet") {
      self.change_occurred == false
    }
    hspec_components = handle_spec.split(/#{DEFAULT_COMPONENT_SEPARATOR}/)
    handle = hspec_components[0]
    exceptions = hspec_components[1 .. -1]
    t = @target_for[handle]
    if t != nil then
      t.remove_descendants(exceptions)
      self.change_occurred = true
    end
  end

  # state change commands
  CANCEL, RESUME, FINISH, SUSPEND = 'cancel', 'resume', 'finish', 'suspend'

  # Change the state of the target IDd by 'handle' to 'state'
  def modify_state handle, state
    assert_precondition("No data change yet") {
      self.change_occurred == false
    }
    t = @target_for[handle]
    if t != nil then
      execute_guarded_state_change(t, state)
      self.change_occurred = true
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
