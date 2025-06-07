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
#!!!CMD:binding.irb
    request = message_broker.object(request_object_key)
    builder = command_builder_for[request.command]
    if ! builder.nil? then
      cmd = builder.call(request, manager)
      if cmd then
        cmd.execute
      end
    else
      "[appropriate error message]"
    end
  end

  private

  attr_accessor :message_broker, :manager, :config

  def initialize(config)
    init_command_builder_table
    self.config = config
    app_config = config.app_configuration
    self.message_broker = app_config.application_message_broker
    initialize_pubsub_broker(app_config)
    self.manager =
      config.new_stodo_manager(service_name: Configuration.service_name,
                               debugging: true)
    # dummy:
    options = TemplateOptions.new([], true)
    target_builder = TemplateTargetBuilder.new(options,
                                     manager.existing_targets, nil, config)
    target_builder.set_processing_mode TemplateTargetBuilder::CREATE_MODE
    manager.target_builder = target_builder
    super(SERVER_RESPONSE_CHANNEL)
  end

end

=begin
# Abstract ancestor - objects for carrying out work for "Worker"s
class HIDEME_WorkCommand

  def execute
  end

  private

  attr_accessor :client_request, :manager

  def initialize(request, manager)
    self.client_request = request
    self.manager = manager
  end

end

class AddCommand < WorkCommand
  public

  def execute
    # strip out the 'command: add'
    opt_args = client_request.arguments[1 .. -1]
    options = TemplateOptions.new(opt_args, true)
    manager.target_builder.spec_collector = options
    manager.add_new_targets
  end

end
=end
