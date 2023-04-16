require 'fileutils'
require 'ruby_contracts'
require 'stodogit'
require 'commandoptions'

# Editors of "STodoTarget"s
class STodoTargetEditor
  include SpecTools, ErrorTools
  include Contracts::DSL

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
      'delete'                => :delete_target,
      'change_parent'         => :change_parent,
      'change_handle'         => :change_handle,
      'remove_descendant'     => :remove_descendant,
      'state'                 => :modify_state,
      'clear_descendants'     => :clear_descendants,
      'clone'                 => :make_clone,
      'git-add'               => :git_add,
      're_adopt_descendants'  => :re_adopt_descendants,
      'remove_false_children' => :remove_false_children,
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
  pre "handle exists" do |handle| ! handle.nil? end
  pre "No data change yet" do change_occurred == false end
  pre "target for 'handle' exists" do |handle|
    ! target_for[handle].nil?
  end
  def delete_target handle, *options
    opts = CommandOptions.new(__method__.to_s, options)
    recursive = opts.recursive?
    t = target_for[handle]
    if recursive then
      t.children.each do |c|
        self.change_occurred = false  # (ensure precondition)
        delete_target c.handle, *options
      end
    end
    if t.parent_handle != nil then
      # "disown" the parent.
      parent = target_for[t.parent_handle]
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
    target_for.delete(t.handle)
    self.change_occurred = true
  end

  # Add/update and commit the item with 'handle'.
  pre "handle exists" do |handle| ! handle.nil? end
  pre "No data change yet" do change_occurred == false end
  pre "target for 'handle' exists" do |handle|
    ! target_for[handle].nil?
  end
  post 'no database change' do change_occurred == false end
  def git_add handle, *options
    opts = CommandOptions.new(__method__.to_s, options)
    recursive = opts.recursive?
    commit_msg = opts.message
    tgt = target_for[handle]
    targets = [tgt]
    if recursive then
      targets.concat(tgt.descendants)
    end
    gitpath = Configuration.instance.git_path
    if ! Dir.exist? gitpath then
      FileUtils.mkdir_p gitpath
    end
    Dir.chdir gitpath do
      repo = STodoGit.new
      targets.each do |t|
        repo.update_file t.handle, t
      end
      repo.commit commit_msg
    end
    # ('git-add' will not change any STodoTarget items.)
    self.change_occurred = false
  end

  # Change parent of item with handle 'handle' to item with handle 'phandle'.
  # If 'phandle' is empty, the item identified by 'handle' is changed to be
  # parentless, i.e., a top-level ancestor.
  # Note: If the item with handle 'phandle' is a child of the item with
  # 'handle' - i.e., the request is to make the child (phandle) the parent
  # of its own parent (handle), this recursive relationship is not created
  # and a warning message to that effect is logged.
  pre "handle exists" do |handle| ! handle.nil? end
  pre "No data change yet" do self.change_occurred == false end
  pre "target for 'handle' exists" do |handle|
    ! self.target_for[handle].nil?
  end
  pre "phandle exists" do |h, phandle| ! phandle.nil?  end
  def change_parent handle, phandle
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
    elsif ! make_orphan && t.is_parent?(new_parent) then
      $log.warn(recursive_child_parent_msg(handle, phandle))
    else
      # The request is valid - go ahead with the change.
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

  pre "No data change yet" do self.change_occurred == false end
  pre "handle exists" do |handle| ! handle.nil? end
  pre "target for 'handle' exists" do |handle|
    ! self.target_for[handle].nil?
  end
  pre "new_handle exists" do |handle, new_handle|
    ! new_handle.nil?
  end
  post "target's handle set to 'new_handle'" do |result, handle, new_handle|
    ! self.target_for[new_handle].nil? &&
      self.target_for[new_handle].handle == new_handle
  end
  def change_handle(handle, new_handle)
    if target_for[new_handle] then
      $log.warn(new_handle_in_use_msg(handle, new_handle))
    else
      t = self.target_for[handle]
      # Remove the old hash entry, associated with the old 'handle' key:
      self.target_for.delete(t.handle)
      t.change_handle(new_handle)
      self.target_for[new_handle] = t
      self.change_occurred = true
    end
  end

  # Remove item with handle 'dhandle' as descendant of item with handle
  # 'handle' - so that it is no longer a descendant - and delete it - that
  # is, remove it from the database of stored items.
  pre "handle exists" do |handle| ! handle.nil? end
  pre "No data change yet" do self.change_occurred == false end
  pre "target for 'handle' exists" do |handle, dh|
    ! self.target_for[handle].nil?
  end
  pre "'dhandle' exists" do |handle, dhandle| ! dhandle.nil?  end
  def remove_descendant handle, dhandle
    t = target_for[handle]
    t.remove_descendant dhandle
    if ! t.last_removed_descendant.nil? then
      self.target_for.delete(t.last_removed_descendant.handle)
      $log.warn "removed #{t.last_removed_descendant.handle}, "\
        "descendant of #{handle}"
      self.change_occurred = true
      t.clear_last_removed_descendant
    end
  end

  # Clear (delete) all of the specified target's (via 'handle_spec')
  # descendants.
  pre "handle_spec exists" do |handle_spec| ! handle_spec.nil? end
  pre "No data change yet" do self.change_occurred == false end
  def clear_descendants handle_spec
    hspec_components = handle_spec.split(/#{DEFAULT_COMPONENT_SEPARATOR}/)
    handle = hspec_components[0]
    exceptions = hspec_components[1 .. -1]
    t = @target_for[handle]
    if t != nil then
      orig_descs = t.descendants
      orig_desc_count = orig_descs.count
      t.remove_descendants(exceptions)
      orig_descs = orig_descs - t.descendants
      orig_descs.each do |d|
        self.target_for.delete(d.handle)
      end
      # (If t's descendant count didn't change, assume no data change.)
      self.change_occurred = orig_desc_count != t.descendants.count
    end
  end

  # "re-adopt" all of the specified target's (via 'handle')
  # descendants.
  pre "handle exists" do |handle| ! handle.nil? end
  pre "No data change yet" do self.change_occurred == false end
  def re_adopt_descendants handle
    t = @target_for[handle]
    if t != nil then
      t.adopt_descendants
      self.change_occurred = t.last_op_changed_state
    else
      $log.warn "No item found with handle: '#{handle}'"
    end
  end

  # For each child, c, of target, t (whose handle is 'handle') if
  # c.parent_handle is either blank or is the handle of a target other than
  # t, remove c as one of t's children. Perform this same operation
  # recursively on all of t's children.
  pre "handle exists" do |handle| ! handle.nil? end
  pre "No data change yet" do self.change_occurred == false end
  def remove_false_children handle
    t = @target_for[handle]
    if t != nil then
      t.remove_false_children(true)
      self.change_occurred = t.last_op_changed_state
    else
      $log.warn "No item found with handle: '#{handle}'"
    end
  end

  # Create a new STodoTarget descendant that is a clone (minus any children
  # or parent) of the item with handle 'orig_handle' and give the new item
  # the handle 'new_handle'.
  pre "No data change yet" do self.change_occurred == false
  end
  pre "target for 'orig_handle' exists" do |orig_handle|
    ! self.target_for[orig_handle].nil?
  end
  pre "new_handle exists" do |oh, new_handle|
    ! new_handle.nil? && ! new_handle.empty?
  end
  def make_clone orig_handle, new_handle
    if target_for[new_handle].nil? then
      t = self.target_for[orig_handle]
      clone = t.clone
      clone.handle = new_handle
      clone.parent_handle = nil
      target_for[clone.handle] = clone
      self.change_occurred = true
    else
      $log.warn "cloning error: handle #{new_handle} is already in use."
    end
  end

  # state change commands
  CANCEL, RESUME, FINISH, SUSPEND = 'cancel', 'resume', 'finish', 'suspend'

  # Change the state of the target IDd by 'handle' to 'state'
  pre "No data change yet" do self.change_occurred == false end
  def modify_state handle, state
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
