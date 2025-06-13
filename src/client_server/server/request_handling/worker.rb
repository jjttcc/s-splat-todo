require 'publisher'
require 'stodo_services_constants'
require 'command_line_request'
require 'templatetargetbuilder'
require 'templateoptions'
require 'command_facilities'

#!!!!Does this need to be a Publisher?:
class Worker < Publisher
  include STodoServicesConstants, CommandFacilities

  public

  # The client request - made available to the command
  attr_reader :request

  def delegate_request(request_object_key)
#!!!binding.irb
    @request = message_broker.object(request_object_key)
    cmd = command_for[request.command]
#[also add this to WorkServer:]
    if ! request.session_id.nil? then
      client_session_object = message_broker.object(request.session_id)
      if ! client_session_object.nil? then
        cmd.client_session = client_session_object
      end
    end
#[end: also add this to WorkServer:]
    if ! cmd.nil? then
#!!!      cmd.execute(request)
      cmd.execute(self)
    else
      "!!![appropriate error message]!!!"
    end
  end

  # Insert the ClientSession, s. into the database and publish the
  # session id for the client.
  def send_session(s)
    message_broker.set_object(s.session_id, s, s.expiration_secs)
    publish(s.session_id)
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
