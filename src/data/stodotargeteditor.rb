# Editors of "STodoTarget"s
class STodoTargetEditor

  public

  attr_reader :last_command_failed, :last_failure_message

  def apply_command(handle, command)
    @last_command_failed = false
    if @target_for[handle] == nil then
      @last_command_failed = true
      @last_failure_message = "No target found with handle #{handle}."
    else
      method = @method_for[command]
      if method == nil then
        @last_command_failed = true
        @last_failure_message = "Invalid command: #{command}."
      else
        self.send(method, handle)
      end
    end
  end

  private

  def initialize(target_map)
    @target_for = target_map
    initialize_method_map
  end

  def initialize_method_map
    @method_for = {
      'delete' => :delete_target,
    }
  end

  def delete_target handle
    t = @target_for[handle]
    if t.parent_handle != nil then
      parent = @target_for[t.parent_handle]
      if parent and parent.can_have_children? then
        parent.remove_child(t)
      end
    end
    @target_for.delete(handle)
  end

end
