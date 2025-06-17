require 'ruby_contracts'
require 'command_constants'
require 'add_command'
require 'delete_command'
require 'change_command'
require 'change_handle_command'
require 'clear_descendants_command'
require 'remove_descendant_command'
require 'clone_command'
require 'session_request_command'
require 'state_change_command'

module CommandFacilities
  include CommandConstants, Contracts::DSL

  # hash table: 'command_for[cmd_name]'
  attr_reader :command_for

  private

  pre :manager_good do ! manager.nil? end
  def init_command_table(config, manager)
    @command_for = {
      ADD_CMD          => AddCommand.new(config, manager),
      CHANGE_CMD       => ChangeCommand.new(config, manager),
      CH_HANDLE_CMD    => ChangeHandleCommand.new(config, manager),
      CLEAR_DESC_CMD   => ClearDescendantsCommand.new(config, manager),
      CLONE_CMD        => CloneCommand.new(config, manager),
      DELETE_CMD       => DeleteCommand.new(config, manager),
      REMOVE_DESC_CMD  => RemoveDescendantCommand.new(config, manager),
      STATE_CHANGE_CMD => StateChangeCommand.new(config, manager),
      SESSION_REQ_CMD  => SessionRequestCommand.new(config, manager)
    }
  end

end
