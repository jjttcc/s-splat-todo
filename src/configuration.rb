require 'logger'

# Configuration settings for the current run
class Configuration
  include SpecTools

  public

  # path of the stodo specification files
  attr_reader :spec_path
  # command to use to send email
  attr_reader :templated_email_command

  # Is this a test run?
  def test_run?
    @test_run
  end

  private

  def initialize
    @spec_path = '../testdir'  # (Temporarily hard-coded for early testing)
    # (Temporarily hard-coded for early testing):
    @templated_email_command = 'mutt -s <subject> <addrs>'
    @test_run = true
  end

  $log = Logger.new(STDERR)
  if ENV[STLOG_LEVEL] then
    $log.level = ENV[STLOG_LEVEL]
  else
    $log.level = Logger::DEBUG
  end
end
