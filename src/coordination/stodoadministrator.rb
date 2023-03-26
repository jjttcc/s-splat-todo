require 'ruby_contracts'
require 'errortools'

# Basic manager of s*todo actions
class STodoAdministrator
  include ErrorTools, Contracts::DSL

  public

  TMPEXPR = '(\btmp|\btemp)'

  public

  # Execute the specified command
  pre 'arg != nil' do |cmd_args| ! cmd_args.nil? end
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

  pre  'global config exists' do ! Configuration.config.nil?  end
  def initialize
    @config = Configuration.config
    initialize_method_map
  end

  def initialize_method_map
    @method_for = {
      'backup' => :perform_data_backup,
    }
  end

  ### Methods for @method_for table

  # Backup the persistent data file.
  pre 'args != nil' do |args| ! args.nil? end
  def perform_data_backup args
    temporary = false
    if ! args.empty? then
      if args[0] =~ /#{TMPEXPR}/i then
        temporary = true
      else
        msg = "invalid 'backup' argument: '#{args[0]}'"
        $log.warn msg
        raise msg
      end
    end
    # Force loading of persistent classes:
    ['project', 'memorandum', 'scheduledevent'].each do |basename|
      require basename
    end
    if temporary then
      @config.data_manager.perform_temporary_backup
      tmp_path = @config.data_manager.last_temp_backup_path
      if ! tmp_path.empty? then
        msg = "backup file:\n#{tmp_path}"
        $log.warn msg
        puts msg
      end
    else
      @config.data_manager.backup_database(@config.backup_paths)
    end
  end

end
