#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'publisher_subscriber'
require 'stodo_services_constants'
require 'configuration'
require 'service'
require 'command_line_request'
require 'command_constants'
require 'client_session'
require 'string_extensions'

# Makes requests for stodo services to implement a REPL interface that
# mimics the 'stodo' CLI.
class STodoCliREPL < PublisherSubscriber
  include STodoServicesConstants, Service, CommandConstants

  private

  def pre_process(exe_args)
    if ! suppress_prompt then
      print PROMPT
    end
  end

  def process(exe_args)
    command_line_request.command = nil
    line = $stdin.gets
    if ! line.nil? then
      begin
        # Try to parse as JSON first
        parsed_request = JSON.parse(line)
        command_line_request.command = parsed_request['command']
        command_line_request.arguments = parsed_request['args']
      rescue JSON::ParserError
        # If JSON parsing fails, treat as plain text command
        components = line.tokenize
        if
          components.count > 0 && ! (components[0] =~ /^#/) &&
            ! components[0].nil? && ! components[0].empty?
        then
          command_line_request.command = components[0]
          # For plain text, the arguments array should include the command itself
          command_line_request.arguments = components
        else
          # Empty or commented line, do nothing
          return
        end
      end

      key = new_key
      message_broker.set_object(key, command_line_request)
      publish(key)
    else
      exit 0
    end
  end

  def request_client_session
    command_line_request.command = SESSION_REQ_CMD
    key = new_key
    message_broker.set_object(key, command_line_request)
    publish(key)
    subscribe_once do
      session_id = last_message
      if ! session_id.nil? then
        command_line_request.session_id = session_id
      else
        $log.error("received a 'nil' session_id from server")
      end
    end
  end

  def post_process(exe_args)
    if command_line_request.command then
      # subscribe to response
      subscribe_once do
        puts last_message
      end
    end
  end

  private

  attr_accessor :message_broker, :command_line_request, :database
  attr_accessor :user_id, :app_name, :session
  attr_reader   :suppress_prompt

  CLI_KEY_BASE = 'client-repl-request'
  PROMPT       = '> '

  def initialize
    Configuration.service_name = 'cli-client'
    Configuration.debugging = false
    config = Configuration.instance
    self.database = config.data_manager
    set_user_and_appname
    ARGV.shift(2) # Remove user_id and app_name from ARGV
    # Parse command-line arguments for --no-prompt / -np
    @suppress_prompt = false
    ARGV.each_with_index do |arg, i|
      if arg == '--no-prompt' || arg == '-np' then
        @suppress_prompt = true
        ARGV.delete_at(i) # Remove the argument from ARGV
        break
      end
    end
    app_config = config.app_configuration
    self.message_broker = app_config.application_message_broker
    initialize_pubsub_broker(app_config)
    init_pubsub(default_pubchan: SERVER_REQUEST_CHANNEL,
                default_subchan: SERVER_RESPONSE_CHANNEL)
    self.command_line_request = CommandLineRequest.new(user_id, app_name)
    request_client_session
  end

  def old_initialize
    Configuration.service_name = 'cli-client'
    Configuration.debugging = false
    config = Configuration.instance
    self.database = config.data_manager
    # Extract user_id and app_name first
    if ARGV.count < 2 then
      usage
      exit ERROR_EXIT
    end
    self.user_id = ARGV[0]
    self.app_name = ARGV[1]
    ARGV.shift(2) # Remove user_id and app_name from ARGV
    # Parse command-line arguments for --no-prompt / -np
    @suppress_prompt = false
    ARGV.each_with_index do |arg, i|
      if arg == '--no-prompt' || arg == '-np' then
        @suppress_prompt = true
        ARGV.delete_at(i) # Remove the argument from ARGV
        break
      end
    end
    set_user_and_appname
    app_config = config.app_configuration
    self.message_broker = app_config.application_message_broker
    initialize_pubsub_broker(app_config)
    init_pubsub(default_pubchan: SERVER_REQUEST_CHANNEL,
                default_subchan: SERVER_RESPONSE_CHANNEL)
    self.command_line_request = CommandLineRequest.new(user_id, app_name)
    request_client_session
  end

  private   ###  Implementation

  ERROR_EXIT = 99

  def new_key
    time = Time.now
    result = time.strftime("#{CLI_KEY_BASE}:%Y-%m-%d.%H%M%S.%6N.#{$$}")
    result
  end

  # Extract user_id and app_name from ARGV and call
  # database.set_appname_and_user with these values.
  def set_user_and_appname
    if ARGV.count < 2 then
      usage
      exit ERROR_EXIT
    end
    self.user_id = ARGV[0]
    self.app_name = ARGV[1]
    database.set_appname_and_user(app_name, user_id)
  end

  def usage
    puts "Usage: #{$0} <user-id> <app-name>"
  end

end
