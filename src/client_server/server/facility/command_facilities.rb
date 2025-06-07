require 'command_constants'
require 'add_command'
require 'delete_command'
require 'change_command'
require 'clear_command'
require 'remove_descendants_command'
require 'clone_command'
require 'state_change_command'

module CommandFacilities
  include CommandConstants

  # hash table: 'command_builder_for[cmd_name]'
  attr_reader :command_builder_for

  private

  def init_command_builder_table
    @command_builder_for = {
      ADD_CMD        => lambda do |req, mgr| AddCommand.new(req, mgr) end,
      DELETE_CMD     => lambda do |req, mgr| DeleteCommand.new(req, mgr) end,
      CHANGE_CMD     => lambda do |req, mgr| ChangeCommand.new(req, mgr) end,
      CLEAR_DESC_CMD => lambda do |req, mgr|
        ClearDescendantsCommand.new(req, mgr)
      end,
    }
=begin
    # Define "type" aliases.
    @target_factory_for[TASK] = @target_factory_for[TASK_ALIAS1]
    @target_factory_for[NOTE_ALIAS1] = @target_factory_for[NOTE]
    @target_factory_for[NOTE_ALIAS2] = @target_factory_for[NOTE]
    @target_factory_for[APPOINTMENT_ALIAS1] = @target_factory_for[APPOINTMENT]
    @target_factory_for[APPOINTMENT_ALIAS2] = @target_factory_for[APPOINTMENT]
=end
  end

end
