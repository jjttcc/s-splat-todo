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
    STATE           => :update_items,
    GIT_ADD         => :update_items,
  }

  # The STodoGit command for the specified 'edit_cmd'
  def git_command_for edit_cmd
$log.warn "[#{__method__}] edit_cmd: #{edit_cmd}"
$log.warn "[#{__method__}] GIT_COMMAND_FOR[edit_cmd]: #{GIT_COMMAND_FOR[edit_cmd]}"
    GIT_COMMAND_FOR[edit_cmd]
  end

  # The plural version (i.e., takes multiple items) of the STodoGit command
  # for the specified 'edit_cmd'
  def git_plural_command_for edit_cmd
$log.warn "[#{__method__}] edit_cmd: #{edit_cmd}"
$log.warn "[#{__method__}] GIT_COMMAND_FOR[edit_cmd]: #{GIT_COMMAND_FOR[edit_cmd]}"
    GIT_PLURAL_COMMAND_FOR[edit_cmd]
  end

  # Use 'repo' to execute the git command corresponding to 'editing_cmd'
  # on 'item'.
  pre 'ed_cmd symbol' do |ed_cmd| ! ed_cmd.nil? && ed_cmd.is_a?(Symbol) end
  pre 'item type' do |ec, item|
    ! item.nil? && (item.is_a?(STodoTarget) || item.is_a?(Enumerable))
  end
  def execute_git_command(editing_cmd, item)
#a.is_a?(Enumerable)'
    repo = Configuration.instance.stodo_git
$log.warn "[#{__method__}] editing_cmd: #{editing_cmd}"
    if item.is_a?(Enumerable) then
      command = git_plural_command_for(editing_cmd)
    else
      command = git_command_for(editing_cmd)
    end
    repo.send(command, item)
  end

  # Use 'repo' to execute the git command corresponding to 'editing_cmd'
  # on 'item'.
  pre 'repo is-git' do |repo| ! repo.nil? && repo.is_a?(STodoGit) end
  pre 'ed_cmd symbol' do |r, ed_cmd| ! ed_cmd.nil? && ed_cmd.is_a?(Symbol) end
  pre 'item type' do |r, ec, item| ! item.nil? && item.is_a?(STodoTarget) end
  def v1___execute_git_command(repo, editing_cmd, item)
$log.warn "[#{__method__}] editing_cmd: #{editing_cmd}"
    command = git_command_for(editing_cmd)
    repo.send(command, item)
    if ! @git_cmd_count then
      @git_cmd_count = 0
    end
    @git_cmd_count += 1
    at_exit do
      git_commit(repo,
                 "committing #{@git_cmd_count} operations (#{editing_cmd}...)")
    end
  end

  # If a STodoGit commit is pending, execute it.
  def do_pending_commit(msg = nil)
    repo = Configuration.instance.stodo_git
    if repo.commit_pending then
$log.warn "#{self.class}.#{__method__} - committing"
      repo.commit msg
    else
$log.warn "#{self.class}.#{__method__} - NO commits pending"
    end
  end

end
