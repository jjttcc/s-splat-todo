require 'ruby_contracts'

# Facilities for mapping stodo editing commands to STodoGit commands
module EditingToGitFacilities
  include Contracts::DSL

  private

  # Constants for stodo editing commands
  DELETE                 =  'delete'
  CHANGE_PARENT          =  'change_parent'
  CHANGE_HANDLE          =  'change_handle'
  REMOVE_DESCENDANT      =  'remove_descendant'
  STATE                  =  'state'
  CLEAR_DESCENDANTS      =  'clear_descendants'
  CLONE                  =  'clone'
  RE_ADOPT_DESCENDANTS   =  're_adopt_descendants'
  REMOVE_FALSE_CHILDREN  =  'remove_false_children'
  # (Not technically a "stodo editing" command, but this seems the best
  # place to put it:)
  GIT_ADD                =  'git-add'

  # For convenience - edit-command existence map
  EDIT_COMMANDS = {
    DELETE                 => true,
    CHANGE_PARENT          => true,
    CHANGE_HANDLE          => true,
    REMOVE_DESCENDANT      => true,
    STATE                  => true,
    CLEAR_DESCENDANTS      => true,
    CLONE                  => true,
    RE_ADOPT_DESCENDANTS   => true,
    REMOVE_FALSE_CHILDREN  => true,
  }

  # Mapping of command "stodo editing" commands to STodoGit commands
  # (Commands that aren't mapped - produce nil - do not correspond to a
  # STodoGit action.)
  GIT_COMMAND_FOR = {
    DELETE          => :delete_item,
    CHANGE_PARENT   => :update_item,
    CHANGE_HANDLE   => :nil,
    STATE           => :update_item,
    GIT_ADD         => :update_item,
  }

  # Mapping of command "stodo editing" commands to plural version of
  # STodoGit commands
  # (Commands that aren't mapped - produce nil - do not correspond to a
  # STodoGit action.)
  GIT_PLURAL_COMMAND_FOR = {
    DELETE          => nil,             # not valid for delete
    CHANGE_PARENT   => nil,             # not valid for change_parent
    CHANGE_HANDLE   => :move_file,
    STATE           => :update_items,
    GIT_ADD         => :update_items,
  }

  # The STodoGit command for the specified 'edit_cmd'
  def git_command_for edit_cmd
    GIT_COMMAND_FOR[edit_cmd]
  end

  # The plural version (i.e., takes multiple items) of the STodoGit command
  # for the specified 'edit_cmd'
  def git_plural_command_for edit_cmd
    GIT_PLURAL_COMMAND_FOR[edit_cmd]
  end

  # Use 'repo' to execute the git command corresponding to 'editing_cmd'
  # on 'item'.
  pre 'ed_cmd symbol' do |ed_cmd| ! ed_cmd.nil? && ed_cmd.is_a?(Symbol) end
  pre 'item type' do |ec, item|
    ! item.nil? && (item.is_a?(STodoTarget) || item.is_a?(Enumerable))
  end
  def execute_git_command(editing_cmd, item)
    repo = Configuration.instance.stodo_git
    if item.is_a?(Enumerable) then
      command = git_plural_command_for(editing_cmd)
    else
      command = git_command_for(editing_cmd)
    end
    repo.send(command, item)
  end

  # If a STodoGit commit is pending, execute it.
  def do_pending_commit(msg = nil)
    repo = Configuration.instance.stodo_git
    if repo.commit_pending then
      repo.commit msg
    else
    end
  end

end
