require 'publisher_subscriber'
require 'stodo_services_constants'
require 'command_line_request'
require 'templatetargetbuilder'
require 'templateoptions'
require 'command_facilities'
require 'client_request_handler'

# Servers that carry out work delegated by a coordinating server
class WorkServer < PublisherSubscriber
  include ClientRequestHandler, STodoServicesConstants, Service,
    CommandFacilities

  public

  # (Make the 'process_request' method private:)
  private :process_request

  private

  attr_accessor :server_id

  def initialize(server_id)
    self.server_id = server_id
    Configuration.service_name = server_id
    Configuration.debugging = false
    init_crh_attributes(Configuration.instance)
    init_pubsub(default_pubchan: SERVER_RESPONSE_CHANNEL,
                default_subchan: server_id)
  end

  ##### Hook methods

  def process(args = nil)
    subscribe_once do
      process_request(last_message)
    end
    message_broker.set_message(server_id, "ready")
  end

end
