require 'publisher'
require 'stodo_services_constants'
require 'command_line_request'
require 'templatetargetbuilder'
require 'templateoptions'
require 'command_facilities'
require 'client_request_handler'

class Worker < Publisher
  include ClientRequestHandler, STodoServicesConstants, CommandFacilities

  public

  alias_method :delegate_request, :process_request

  private

  attr_accessor :manager, :config

  def initialize(config)
    self.config = config
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
    target_builder.set_processing_mode TemplateTargetBuilder::CREATE_MODE
    manager.target_builder = target_builder
    super(SERVER_RESPONSE_CHANNEL)
  end

end
