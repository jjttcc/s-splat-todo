require 'ruby_contracts'

# Client request-handling behavior
# Descendants must implement the 'publish' method.
module ClientRequestHandler
  include Contracts::DSL, ErrorTools

  public

  SUCCESS_REPORT = "Succeeded"
  FAIL_BASE = "Command failed"

  # The client request - made available to the command
  attr_reader :request, :database, :config

  alias_method :configuration, :config

  def process_request(request_object_key)
    @request = message_broker.object(request_object_key)
    cmd = command_for[request.command]
    if cmd.nil? then
      publish("Invalid command: #{request.command}")
    else
      if ! request.session_id.nil? then
        client_session_object = message_broker.object(request.session_id)
        if ! client_session_object.nil? then
          database.set_appname_and_user(client_session_object.app_name,
                                        client_session_object.user_id)
          cmd.client_session = client_session_object
        end
      end
      cmd.execute(self)
      if cmd.execution_succeeded then
        if ! cmd.response.empty? then # If it succeeded but also has a message
          publish(cmd.response)      # Publish the message
        else
          publish(SUCCESS_REPORT)    # Otherwise, publish "Succeeded"
        end
      else
        msg = FAIL_BASE
        if ! cmd.response.empty? then
          msg = "#{msg}: #{cmd.response}"
        end
        publish(msg)
      end
    end
  end

  # Insert the ClientSession, s. into the database and publish the
  # session id for the client.
  def send_session(s)
    message_broker.set_object(s.session_id, s, s.expiration_secs)
    publish(s.session_id)
  end

  private

  attr_accessor :message_broker
  attr_writer   :database, :config

  pre  :cfg_exists do |cfg| ! cfg.nil? end
  post :config_set do |result, cfg| self.config == cfg end
  def init_crh_attributes(cfg)
    self.config = cfg
    app_config = config.app_configuration
    self.database = config.data_manager
    self.message_broker = app_config.application_message_broker
    initialize_pubsub_broker(app_config)
    init_command_table(config)
  end

end
