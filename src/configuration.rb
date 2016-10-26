require 'logger'
require 'fileutils'
require_relative 'filebaseddatamanager'
require_relative 'spectools'
require_relative 'configtools'

# Configuration settings for the current run
class Configuration
  include SpecTools, ConfigTools, FileTest, FileUtils

  public

  # path of the stodo specification files
  attr_reader :spec_path
  # path of the stodo specification files after they have been initially
  # processed
  attr_reader :post_init_spec_path
  # path for application data files
  attr_reader :data_path
  # command to use to send email
  attr_reader :templated_email_command
  # calendar application for submitting calendar entries
  attr_reader :calendar_tool
  attr_reader :data_manager

  # Is this a test run?
  def test_run?
    @test_run
  end

  private

  def initialize
    setup_config_path
    settings = config_file_settings
    set_config_vars settings
    @test_run = ENV[STTESTRUN] != nil
    @data_manager = FileBasedDataManager.new(data_path)
  end

  def set_config_vars settings
    @spec_path = settings[SPEC_PATH_TAG]
    @data_path = settings[DATA_PATH_TAG]
    @post_init_spec_path =
      ConfigTools::constructed_path([data_path, OLD_SPECS_TAG])
    @templated_email_command = settings[EMAIL_TEMPLATE_TAG]
    # Hard-coded - may or may-not be made configurable later:
    @calendar_tool = 'gcalcli'
    validate_paths(spec_path, data_path, post_init_spec_path)
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
  def validate_paths *paths
    errors = []
    paths.each do |p|
      if not File.readable?(p) then
        if not File.exists?(p) then
          errors << "File '#{p}' does not exist."
        else
          errors << "File '#{p}' does is not readable."
        end
      end
    end
    if errors.length > 0 then
      $log.fatal "Needed directories are not readable:\n" + errors.join("\n")
      raise "Fatal error: Missing or unreadable system directories"
    end
  end

  $log = Logger.new(STDERR)
  $debug = ENV[STDEBUG] != nil
  if ENV[STLOG_LEVEL] then
    $log.level = ENV[STLOG_LEVEL]
  else
    $log.level = $debug? Logger::DEBUG: Logger::WARN
  end
end
