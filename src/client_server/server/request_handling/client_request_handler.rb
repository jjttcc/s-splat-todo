
# Client request-handling behavior
module ClientRequestHandler

  public

  # The client request - made available to the command
  attr_reader :request

  def process_request(request_object_key)
    @request = message_broker.object(request_object_key)
    cmd = command_for[request.command]
    if ! request.session_id.nil? then
      client_session_object = message_broker.object(request.session_id)
      if ! client_session_object.nil? then
        database.set_appname_and_user(client_session_object.app_name,
                                      client_session_object.user_id)
        cmd.client_session = client_session_object
      end
    end
    if ! cmd.nil? then
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

  attr_accessor :message_broker, :database

end
