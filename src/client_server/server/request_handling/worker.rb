require 'publisher'
require 'stodo_services_constants'
require 'command_line_request'
require 'templatetargetbuilder'
require 'templateoptions'

class Worker < Publisher
  include STodoServicesConstants

  public

  def process_request(request_object_key)
    request = message_broker.object(request_object_key)
    # stublike:
### Need a hash table of WorkCommand subclass creators:
    case request.command
    when 'add'
      cmd = AddCommand.new(request, manager)
    end
    puts "request: #{request.inspect}"
    if cmd then
      cmd.execute
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
    # dummy:
    options = TemplateOptions.new([], true)
    target_builder = TemplateTargetBuilder.new(options,
                                     manager.existing_targets, nil, config)
    target_builder.set_processing_mode TemplateTargetBuilder::CREATE_MODE
    manager.target_builder = target_builder
    super(SERVER_RESPONSE_CHANNEL)
  end

end

#!!!to-do: Move the code for these classes into their own files:

# Abstract ancestor - objects for carrying out work for "Worker"s
class WorkCommand

  def execute
  end

  private

  attr_accessor :client_request, :manager

  def initialize(request, manager)
    self.client_request = request
    self.manager = manager
  end

end

# rename - such as (don't just use it for 'add'):
#class CommandWithArgs < WorkCommand
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
