require 'subscriber'
#require 'stodo_services_constants'
require 'command_line_request'
require 'templatetargetbuilder'
require 'templateoptions'
require 'command_facilities'

# Servers that carry out work delegated by a coordinating server
class WorkServer < Subscriber
  include Service, CommandFacilities

  public

  private

  attr_accessor :message_broker, :manager, :server_id

  def initialize(server_id)
    self.server_id = server_id
    Configuration.service_name = server_id
    Configuration.debugging = false
    config = Configuration.instance
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
    manager.target_builder = target_builder
    super(server_id)
$tlog = File.new("/tmp/#{server_id}", "w")
$tlog.puts("subscribe channel should be #{default_subscription_channel}")
$tlog.flush
  end

  def process_request(request_object_key)
$tlog.puts("[process_request]: rok: #{request_object_key}")
$tlog.flush
    request = message_broker.object(request_object_key)
    cmd = command_for[request.command]
$tlog.puts("[process_request]: req, cmd:",
           request.inspect, cmd.inspect)
$tlog.flush
    if ! cmd.nil? then
      cmd.execute(request)
$tlog.puts("[process_request]: command executed")
$tlog.flush
    else
      "!!![appropriate error message]!!!"
    end
  end

  ##### Hook methods

  def process(args = nil)
$tlog.puts("[process]: subscribing to #{default_subscription_channel}")
    subscribe_once do
      process_request(last_message)
    end
$tlog.puts("[process]: calling message_broker.set_message")
$tlog.puts("[process]: server_id: #{server_id.inspect}")
$tlog.flush
    message_broker.set_message(server_id, "ready")
$tlog.puts("[process]: finished - set msg(#{server_id}) to ready")
$tlog.flush
  end

end
