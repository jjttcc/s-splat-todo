#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'subscriber'
require 'service'
require 'stodo_services_constants'
require 'configuration'
require 'worker'


# Responds to client requests for stodo services (which are modeled after
# the 'stodo' CLI interface)
class STodoServer < Subscriber
  include Service, STodoServicesConstants

  public

  private

  MAIN_LOOP_PAUSE_SECONDS = 0.15

  attr_accessor :worker

  def initialize
    Configuration.service_name = 'main-server'
    Configuration.debugging = false
    config = Configuration.instance
    app_config = config.app_configuration
    #!!!We need a "pool" of workers!!!
    self.worker = Worker.new(config)
    initialize_pubsub_broker(app_config)
    super(SERVER_REQUEST_CHANNEL)
  end

  ##### Hook methods

  def process(args = nil)
    subscribe_once do
      worker.process_request(last_message)
    end
  end

end
