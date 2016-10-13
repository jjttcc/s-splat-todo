require 'logger'

# Configuration settings for the current run
class Configuration
  # path of the stodo specification files
  attr_reader :spec_path
  # command to use to send email
  attr_reader :templated_email_command

  private

  def initialize
    @spec_path = '../testdir'  # (Temporarily hard-coded for early testing)
    # (Temporarily hard-coded for early testing):
    @templated_email_command = 'mutt -s <subject> <addrs>'
  end

  $log = Logger.new(STDERR)
  $log.level = Logger::WARN
end
