require 'ruby_contracts'
require 'command_constants'
require 'add_command'
require 'delete_command'
require 'change_command'
require 'change_handle_command'
require 'clear_descendants_command'
require 'remove_descendant_command'
require 'clone_command'
require 'report_command'
require 'session_request_command'
require 'state_change_command'

module CommandFacilities
  include CommandConstants, Contracts::DSL

  # hash table: 'command_for[cmd_name]'
  attr_reader :command_for

  private

  pre :manager_good do ! manager.nil? end
  def init_command_table(config)
    @command_for = {
      ADD_CMD          => AddCommand.new(config),
      CHANGE_CMD       => ChangeCommand.new(config),
      CH_HANDLE_CMD    => ChangeHandleCommand.new(config),
      CLEAR_DESC_CMD   => ClearDescendantsCommand.new(config),
      CLONE_CMD        => CloneCommand.new(config),
      DELETE_CMD       => DeleteCommand.new(config),
      REMOVE_DESC_CMD  => RemoveDescendantCommand.new(config),
      STATE_CHANGE_CMD => StateChangeCommand.new(config),
      SESSION_REQ_CMD  => SessionRequestCommand.new(config),
      REPORT_CMD       => ReportCommand.new(config)
    }
  end

end
