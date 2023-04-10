require 'ruby_contracts'
require 'singleton'
require 'logger'
require 'fileutils'
require 'yamlstorebaseddatamanager'
require 'spectools'
require 'configtools'
require 'mediaconfigtools'

# Configuration settings for the current run
class Configuration
  include Singleton
  include ConfigTools, MediaConfigTools, FileTest, FileUtils
  include Contracts::DSL

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
  # path for user files
  attr_reader :user_path
  # default/backup email address
  attr_reader :default_email
  # path(s) for backups of data files
  attr_reader :backup_paths
  # command to use to send email
  attr_reader :templated_email_command
  # calendar application for submitting calendar entries
  attr_reader :calendar_tool
  # prefix to use for categories in some reports
  attr_reader :category_prefix
  attr_reader :data_manager

  # Should attachments be "viewed" (not modified) during this run?
  attr_reader :view_attachment
  # Should attachments be "edited" (potentially modified) during this run?
  attr_reader :edit_attachment

  VERSION =  '1.0.1'
  PROGNAME = 'stodo'

  # stodo version identifier
  def version
    VERSION
  end

  def name
    PROGNAME
  end

  # stodo configuration/settings
  def settings
    result = {
      'config file path'        => CONFIG_FILE_PATH,
      "user"                    => user,
      "user_path"               => user_path,
      "spec_path"               => spec_path,
      "data_path"               => data_path,
      "backup_paths"            => backup_paths,
      "post_init_spec_path"     => post_init_spec_path,
      "default_email"           => default_email,
      "templated_email_command" => templated_email_command,
    }
    result
  end

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

  attr_writer :view_attachment, :edit_attachment

  def initialize
    setup_config_path
    settings = config_file_settings
    set_config_vars settings
    set_external_media_tools settings
    set_internal_vars
    @test_run = ENV[STTESTRUN] != nil
    @data_manager = YamlStoreBasedDataManager.new(data_path, user)
  end

  def set_config_vars settings
    @user = user_name settings
    @category_prefix = cat_prefix settings
    @spec_path = settings[SPEC_PATH_TAG]
    @data_path = settings[DATA_PATH_TAG]
    @user_path = settings[USER_PATH_TAG]
    @default_email = settings[DEFAULT_EMAIL_TAG]
    @post_init_spec_path =
      ConfigTools::constructed_path([data_path, OLD_SPECS_TAG])
    @templated_email_command = settings[EMAIL_TEMPLATE_TAG]
    @calendar_tool = settings[CALENDAR_COMMAND_TAG]
    @backup_paths = scanned_backup_paths(settings[BACKUP_PATH_TAG])
    validate_paths({:spec_path => spec_path, :data_path => data_path,
        :user_path => user_path, :post_init_spec_path => post_init_spec_path})
    validate_paths(labeled_paths(backup_paths))
    validate_exefiles(@calendar_tool)
  end

  # Set values based on "internal" (not generally directly available to the
  # user) environment variables.
  def set_internal_vars
    self.view_attachment = true
    self.edit_attachment = false
    atype_override = ENV[ST_ATTCH_ACTION]
    if ! atype_override.nil? && atype_override == ATTCH_ACTION_EDIT then
      self.edit_attachment = true
      self.view_attachment = false
    end
  end

  def setup_config_path
    if not exist? CONFIG_DIR_PATH then
      begin
        mkdir_p CONFIG_DIR_PATH
      rescue Exception => e
        raise "Fatal error directory #{CONFIG_DIR_PATH} could not be " +
          "created [#{e}]"
      end
    end
    if not exist? CONFIG_FILE_PATH then
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
    # (".select ..." to filter out "# <comment>...":)
    lines = cfgfile.read.split("\n").select do |l| l !~ /^\s*#/ end
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
          if not File.exist?(p) then
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
