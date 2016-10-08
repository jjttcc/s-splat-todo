require 'logger'
require_relative 'actiontargetmanager'

# Configuration settings for the current run
class Configuration
  # path of the stodo specification files
  attr_reader :spec_path, :action_manager

  def initialize
    @spec_path = './testdir'  # (Temporarily hard-coded for early testing)
    @action_manager = ActionTargetManager.new
  end

  $log = Logger.new(STDERR)
  $log.level = Logger::WARN
end
