require 'errortools'

# Basic manager of s*todo actions
class STodoAdministrator
  include ErrorTools

  public

  # Execute the specified command
  def execute(command_with_args)
    command = command_with_args[0]
    method = @method_for[command]
    if method == nil then
      command_failed = true
      failure_message = "Invalid administrative command: #{command}."
    else
      self.send(method, command_with_args[1..-1])
    end
    if command_failed then
      $log.warn failure_message
    end
  end

  private

  def initialize config = nil
    if config != nil then
      @config = config
    end
    initialize_method_map
  end

  def initialize_method_map
    @method_for = {
      'backup' => :perform_data_backup,
    }
  end

  ### Methods for @method_for table

  # Backup the persistent data file.
  def perform_data_backup args
    # Force loading of persisten classes:
    ['project', 'memorandum', 'scheduledevent'].each do |basename|
      require basename
    end
    @config.data_manager.backup_database(@config.backup_paths)
  end

end
