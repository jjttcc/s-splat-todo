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

  private :process_request

  private

  attr_accessor :manager, :server_id

  def initialize(server_id)
    self.server_id = server_id
    Configuration.service_name = server_id
    Configuration.debugging = false
    config = Configuration.instance
    app_config = config.app_configuration
    self.database = config.data_manager
    self.message_broker = app_config.application_message_broker
    initialize_pubsub_broker(app_config)
    self.manager =
      config.new_stodo_manager(service_name: Configuration.service_name,
                               debugging: true)
    init_command_table(manager)
    # dummy:
    options = TemplateOptions.new([], true)
    target_builder = TemplateTargetBuilder.new(options,
                                     manager.existing_targets, nil, config)
    manager.target_builder = target_builder
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
