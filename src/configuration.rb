require 'logger'
require_relative 'filebaseddatamanager'

# Configuration settings for the current run
class Configuration
  include SpecTools

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
    @spec_path = '../testdir'   # (Temporarily hard-coded for early testing)
    @post_init_spec_path = '../datatest/processed_specs'  # (Temporarily ...)
    @data_path = '../datatest'
    # (Temporarily hard-coded for early testing:)
    @templated_email_command = 'mutt -s <subject> <addrs>'
    # (Again - temporarily hard-coded for early testing:)
    @calendar_tool = 'gcalcli'
    @test_run = ENV[STTESTRUN] != nil
    @data_manager = FileBasedDataManager.new(data_path)
  end

  $log = Logger.new(STDERR)
  $debug = ENV[STDEBUG] != nil
  if ENV[STLOG_LEVEL] then
    $log.level = ENV[STLOG_LEVEL]
  else
    $log.level = $debug? Logger::DEBUG: Logger::WARN
  end
end
