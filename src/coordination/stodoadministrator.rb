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
#!!!binding.irb
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

  def initialize(service_name: 'admin', debugging: false)
    # First, set these class attributes in Configuration.
    Configuration.service_name = service_name
    Configuration.debugging = debugging
    # The above Configuration class attributes will be used here (in
    # Configuration.initialize) to set the corresponding singleton
    # attributes):
    Configuration.instance
    initialize_method_map
  end

  def initialize_method_map
    @method_for = {
      'backup' => :perform_data_backup,
      'version' => :print_version,
      'settings' => :print_settings,
      'export' => :export,
      'migrate' => :migrate,
    }
  end

  ### Methods for @method_for table

  # Backup the persistent data file.
  pre 'args != nil' do |args| ! args.nil? end
  def perform_data_backup args
    config = Configuration.instance
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
      config.data_manager.perform_temporary_backup
      tmp_path = config.data_manager.last_temp_backup_path
      if ! tmp_path.empty? then
        msg = "backup file:\n#{tmp_path}"
        $log.warn msg
      end
    else
      config.data_manager.backup_database(config.backup_paths)
    end
  end

  # Backup the persistent data file.
  pre 'args != nil' do |args| ! args.nil? end
  def export args
    config = Configuration.instance
    if ! args.empty? then
      if args.count < 2 then
        $log.warn "Need at least 2 arguments (got: '#{args[0]}')"
      else
        handles = args[0 .. -2]
        path = args.last
      end
    else
      $log.warn "Missing arguments to 'export' command."
    end
   ['project', 'memorandum', 'scheduledevent'].each do |basename|
     require basename
   end
    config.data_manager.export(handles, path, true)
  end

  # Migrate the specified data file to the redis database.
  pre 'args != nil' do |args| ! args.nil? end
  def migrate args
binding.irb
    config = Configuration.instance
    if ! args.empty? then
      path = args[0]
    else
      msg = "Missing argument to 'migrate' command."
      $log.warn msg
      raise msg
    end
    old_data_manager = YamlStoreBasedDataManager.new(path, config.user)
    targets = old_data_manager.restored_targets
#!!!   ['project', 'memorandum', 'scheduledevent'].each do |basename|
#!!!     require basename
#!!!   end
    config.data_manager.store_targets(targets)
  end

  # Print application version information.
  def print_version *dummy
    config = Configuration.instance
    puts "#{config.name} #{config.version}"
  end

  # Print application settings - configuration - information.
  def print_settings *dummy
    config = Configuration.instance
    dbc_status = (config.assertions_enabled?)? "ENABLED": "DISABLED"
    trx_status = config.in_transaction ? "YES": "NO"
    printf("%-26s%s\n", "assertions:", dbc_status);
    printf("%-26s%s\n", "in transaction:", trx_status);
    config.settings.sort.each do |set|
      printf("%-26s%s\n", "#{set[0]}:", set[1]);
    end
  end

end
