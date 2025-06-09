#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'publisher_subscriber'
require 'stodo_services_constants'
require 'configuration'
require 'service'
require 'command_line_request'

# Makes requests for stodo services to implement a REPL interface that
# mimics the 'stodo' CLI.
class STodoCliREPL < PublisherSubscriber
  include STodoServicesConstants, Service

  public

  def prepare_for_main_loop(exe_args)
    self.command_line_request = CommandLineRequest.new
  end

  def pre_process(exe_args)
    print PROMPT
  end

  def process(exe_args)
    line = gets
    if ! line.nil? then
      args = line.chomp.split( / *"(.*?)" *| / )
      if args.count > 0 then
        command_line_request.command = args[0]
        command_line_request.arguments = args
        key = new_key
        message_broker.set_object(key, command_line_request)
        publish(key)
      end
    else
      exit 0
    end
  end

  def post_process(exe_args)
    # subscribe to response
    puts "pretending to subscrib to response"
  end

  private

  attr_accessor :message_broker, :command_line_request

  CLI_KEY_BASE = 'client-repl-request'
  PROMPT       = '> '

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

  private   ###  Implementation

  def new_key
    time = Time.now
    result = time.strftime("#{CLI_KEY_BASE}:%Y-%m-%d.%H%M%S.%6N.#{$$}")
    result
  end

end
