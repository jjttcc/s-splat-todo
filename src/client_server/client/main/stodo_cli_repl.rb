#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'publisher_subscriber'
require 'stodo_services_constants'
require 'configuration'
require 'service'
require 'command_line_request'
require 'command_constants'
require 'client_session'

# From:
#https://stackoverflow.com/questions/11566094/trying-to-split-string-into-single-words-or-quoted-words-and-want-to-keep-the
class String
  def tokenize
    self.
      split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/).
      select {|s| not s.empty? }.
      map {|s| s.gsub(/(^ +)|( +$)|(^["']+)|(["']+$)/,'')}
  end
end

# Makes requests for stodo services to implement a REPL interface that
# mimics the 'stodo' CLI.
class STodoCliREPL < PublisherSubscriber
  include STodoServicesConstants, Service, CommandConstants

  private

  def pre_process(exe_args)
    print PROMPT
  end

  def process(exe_args)
    line = $stdin.gets
    if ! line.nil? then
      components = line.tokenize
      if components.count > 0 then
#!!!Use a filtering tool to correct spelling errors in the
#!!!command - i.e., if possible if what the user types is
#!!!close enough, match/change it to the exact command.
        command_line_request.command = components[0]
        command_line_request.arguments = components
        key = new_key
        message_broker.set_object(key, command_line_request)
        publish(key)
      end
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
    # subscribe to response
    subscribe_once do
      # Temporary!!!:
      puts "got '#{last_message}' from server"
    end
  end

  private

  attr_accessor :message_broker, :command_line_request, :database
  attr_accessor :user_id, :app_name, :session

  CLI_KEY_BASE = 'client-repl-request'
  PROMPT       = '> '

  def initialize
    Configuration.service_name = 'cli-client'
    Configuration.debugging = false
    config = Configuration.instance
    self.database = config.data_manager
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
