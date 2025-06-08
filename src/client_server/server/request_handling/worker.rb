require 'publisher'
require 'stodo_services_constants'
require 'command_line_request'
require 'templatetargetbuilder'
require 'templateoptions'
require 'command_facilities'

class Worker < Publisher
  include STodoServicesConstants, CommandFacilities

  public

  def process_request(request_object_key)
    request = message_broker.object(request_object_key)
    cmd = command_for[request.command]
    if ! cmd.nil? then
      cmd.execute(request)
    else
      "!!![appropriate error message]!!!"
    end
  end

  private

  attr_accessor :message_broker, :manager, :config

  def initialize(config)
    self.config = config
    app_config = config.app_configuration
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
