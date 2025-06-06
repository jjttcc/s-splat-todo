#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'publisher_subscriber'
require 'stodo_services_constants'
require 'stodo_services_constants'
require 'configuration'
require 'request'

# Makes requests for stodo services to implement a CLI interface
class STodoCliClient < PublisherSubscriber
  include STodoServicesConstants

  public

  def execute
    message_broker.set_object(CLI_OBJ_KEY, Request.new)
    publish(CLI_OBJ_KEY)
  end

  private

  attr_accessor :message_broker

  CLI_OBJ_KEY = 'temporary-made-up-key'

  def initialize
    Configuration.service_name = 'cli-client'
    Configuration.debugging = false
    config = Configuration.instance
    app_config = config.app_configuration
    self.message_broker = app_config.application_message_broker
    initialize_pubsub_broker(app_config)
    init_pubsub(default_pubchan: SERVER_REQUEST_CHANNEL,
                default_subchan: SERVER_RESPONSE_CHANNEL)
  end

end
