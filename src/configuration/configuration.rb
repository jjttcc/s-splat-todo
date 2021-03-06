require 'logger'
require 'fileutils'
require 'yamlstorebaseddatamanager'
require 'spectools'
require 'configtools'

# Configuration settings for the current run
class Configuration
  include ConfigTools, FileTest, FileUtils

  public

  # user name/id
  attr_reader :user
  # path of the stodo specification files
  attr_reader :spec_path
  # path of the stodo specification files after they have been initially
  # processed
  attr_reader :post_init_spec_path
  # path for application data files
  attr_reader :data_path
  # path(s) for backups of data files
  attr_reader :backup_paths
  # command to use to send email
  attr_reader :templated_email_command
  # calendar application for submitting calendar entries
  attr_reader :calendar_tool
  # prefix to use for categories in some reports
  attr_reader :category_prefix
  attr_reader :data_manager

  # Is this a test run?
  def test_run?
    @test_run
  end

  if ENV[ST_LOG_PATH] then
    LOGPATH = ENV[ST_LOG_PATH] + File::SEPARATOR + "stodo-log-#{$$}"
  else
    LOGPATH = DEFAULT_LOG_PATH
  end

  private

  def initialize
    setup_config_path
    settings = config_file_settings
    set_config_vars settings
    @test_run = ENV[STTESTRUN] != nil
    @data_manager = YamlStoreBasedDataManager.new(data_path, user)
  end

  def set_config_vars settings
    @user = user_name settings
    @category_prefix = cat_prefix settings
    @spec_path = settings[SPEC_PATH_TAG]
    @data_path = settings[DATA_PATH_TAG]
    @post_init_spec_path =
      ConfigTools::constructed_path([data_path, OLD_SPECS_TAG])
    @templated_email_command = settings[EMAIL_TEMPLATE_TAG]
    @calendar_tool = settings[CALENDAR_COMMAND_TAG]
    @backup_paths = scanned_backup_paths(settings[BACKUP_PATH_TAG])
    validate_paths({:spec_path => spec_path, :data_path => data_path,
      :post_init_spec_path => post_init_spec_path})
    validate_paths(labeled_paths(backup_paths))
    validate_exefiles(@calendar_tool)
  end

  def setup_config_path
    if not exists? CONFIG_DIR_PATH then
      begin
        mkdir_p CONFIG_DIR_PATH
      rescue Exception => e
        raise "Fatal error directory #{CONFIG_DIR_PATH} could not be " +
          "created [#{e}]"
      end
    end
    if not exists? CONFIG_FILE_PATH then
      begin
        f = File.open(CONFIG_FILE_PATH, 'w')
      rescue Exception => e
        raise "Fatal error: file #{CONFIG_FILE_PATH} could not be " +
          "created [#{e}]"
      end
      f.close
    end
  end

  # hash table with config tag as key and value as associated setting
  def config_file_settings
    result = {}
    cfgfile = opened_config_file 'r'
    lines = cfgfile.read.split("\n")
    result = Hash[lines.map { |l| l.split(/\s*=\s*/, 2) }]
    result
  end

  def opened_config_file mode
    begin
      result = File.open(CONFIG_FILE_PATH, mode)
    rescue Exception => e
      raise "Fatal error: file #{CONFIG_FILE_PATH} could not be " +
        "opened for reading [#{e}]"
    end
    result
  end

  # Validate the specified paths - raise an exception if any are found not
  # to exist or are inaccessible.
  def validate_paths paths
    errors = []
    paths.keys.each do |pname|
      p = paths[pname]
      if p == nil then
        errors << "Path not set for '#{pname}'"
      else
        if not File.readable?(p) then
          if not File.exists?(p) then
            errors << "File '#{p}' does not exist."
          else
            errors << "File '#{p}' does is not readable."
          end
        end
      end
    end
    if errors.length > 0 then
      errs = errors.join("\n")
      $log.fatal "Needed directories are not readable:\n" + errs
      raise "Fatal error: Missing or unreadable system directories: #{errs}"
    end
  end

  # Validate the specified paths - raise an exception if any are not found in
  # the path or are not executable.
  def validate_exefiles *paths
    errors = []
    paths.each do |p|
      if ConfigTools::which(p) == nil then
        errors << "Executable file '#{p}' is not in the path."
      end
    end
    if errors.length > 0 then
      $log.fatal "Needed executables were not found:\n" + errors.join("\n")
      raise "Fatal error: Missing executable files (See #{LOGPATH})"
    end
  end

  def scanned_backup_paths p
    result = []
    if p then
      result = p.split(/,\s*/)
    end
    result
  end

  def user_name(settings)
    result = settings[USER_TAG]
    if result == nil || result.empty? then
      require "etc"
      result = Etc.getpwuid.name
    else
      if result =~ /(?:[^[:print:]]|\s)/ then
        msg = "Invalid user name in config file #{result}"
        $log.fatal "#{msg}"
        raise msg
      end
    end
    result
  end

  def cat_prefix(settings)
    result = settings[CATEGORY_PREFIX_TAG]
    if result == nil then
      result = DEFAULT_CAT_PREFIX
    end
    result
  end

  def labeled_paths(pths)
    result = {}
    i = 1
    pths.each do |p|
      result["path-#{i}"] = p
      i += 1
    end
    result
  end

  begin
    $log = Logger.new(LOGPATH)
  rescue Exception => e
    raise "Creation of log file (#{LOGPATH}} failed: #{e}"
  end
  $debug = ENV[STDEBUG] != nil
  if ENV[STLOG_LEVEL] then
    $log.level = ENV[STLOG_LEVEL]
  else
    $log.level = $debug? Logger::DEBUG: Logger::WARN
  end
end
