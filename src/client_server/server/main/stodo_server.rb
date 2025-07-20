#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'subscriber'
require 'service'
require 'stodo_services_constants'
require 'configuration'
require 'work_coordinator'
require 'worker'


# Responds to client requests for stodo services (which are modeled after
# the 'stodo' CLI interface)
class STodoServer < Subscriber
  include Service, STodoServicesConstants, SpecTools

  public

  private

  MAIN_LOOP_PAUSE_SECONDS = 0.15

  attr_accessor :work_coordinator

  if ENV[STTESTRUN] then
    TESTING = true
  else
    TESTING = false
  end

  def initialize
    Configuration.service_name = 'main-server'
    Configuration.debugging = false
    config = Configuration.instance
    app_config = config.app_configuration
    if TESTING then
      # (same-process version for testing)
      self.work_coordinator = Worker.new(config)
    else
      self.work_coordinator = WorkCoordinator.new(config)
    end
    initialize_pubsub_broker(app_config)
    super(SERVER_REQUEST_CHANNEL)
  end

  ##### Hook methods (called within infinite loop)

  def process(args = nil)
    subscribe do
      work_coordinator.delegate_request(last_message)
    end
  end

end
