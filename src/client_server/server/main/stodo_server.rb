#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

#!!!require 'publisher_subscriber'
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

  attr_accessor :manager, :worker

  def initialize
    Configuration.service_name = 'main-server'
    Configuration.debugging = false
    config = Configuration.instance
    self.manager =
      config.new_stodo_manager(service_name: Configuration.service_name,
                               debugging: true)
    app_config = config.app_configuration
    #!!!We need a "pool" of workers!!!
    self.worker = Worker.new(app_config)
    initialize_pubsub_broker(app_config)
    super(SERVER_REQUEST_CHANNEL)
  end

  ##### Hook methods

  def process(args = nil)
#!!!binding.irb
    subscribe_once do
      worker.process_request(last_message)
    end
#manager.perform_ongoing_processing
#!!!    sleep MAIN_LOOP_PAUSE_SECONDS
#!!!binding.irb
  end

end
