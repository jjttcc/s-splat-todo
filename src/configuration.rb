require 'logger'

# Configuration settings for the current run
class Configuration
  include SpecTools

  public

  # path of the stodo specification files
  attr_reader :spec_path
  # command to use to send email
  attr_reader :templated_email_command
  # calendar application for submitting calendar entries
  attr_reader :calendar_tool

  # Is this a test run?
  def test_run?
    @test_run
  end

  private

  def initialize
    @spec_path = '../testdir'  # (Temporarily hard-coded for early testing:)
    # (Temporarily hard-coded for early testing:)
    @templated_email_command = 'mutt -s <subject> <addrs>'
    # (Again - temporarily hard-coded for early testing:)
    @calendar_tool = 'gcalcli'
    @test_run = ENV[STTESTRUN] != nil
  end

  $log = Logger.new(STDERR)
  $debug = ENV[STDEBUG] != nil
  if ENV[STLOG_LEVEL] then
    $log.level = ENV[STLOG_LEVEL]
  else
    $log.level = $debug? Logger::DEBUG: Logger::WARN
  end
end
