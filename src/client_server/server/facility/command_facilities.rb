require 'ruby_contracts'
require 'command_constants'
require 'add_command'
require 'delete_command'
require 'change_command'
require 'change_handle_command'
require 'clear_descendants_command'
require 'remove_descendants_command'
require 'clone_command'
require 'state_change_command'

module CommandFacilities
  include CommandConstants, Contracts::DSL

  # hash table: 'command_for[cmd_name]'
  attr_reader :command_for

  private

  pre :manager_good do ! manager.nil? end
  def init_command_table(manager)
    @command_for = {
      ADD_CMD          => AddCommand.new(manager),
      CHANGE_CMD       => ChangeCommand.new(manager),
      CH_HANDLE_CMD    => ChangeHandleCommand.new(manager),
      CLEAR_DESC_CMD   => ClearDescendantsCommand.new(manager),
      CLONE_CMD        => CloneCommand.new(manager),
      DELETE_CMD       => DeleteCommand.new(manager),
      REMOVE_DESC_CMD  => RemoveDescendantsCommand.new(manager),
      STATE_CHANGE_CMD => StateChangeCommand.new(manager),
    }
  end

end
