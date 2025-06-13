#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'subscriber'
require 'service'
require 'stodo_services_constants'
require 'configuration'
require 'work_coordinator'
require 'worker'


# Responds to client requests for stodo services (which are modeled after
# the 'stodo' CLI interface)
class STodoServer < Subscriber
  include Service, STodoServicesConstants

  public

  private

  MAIN_LOOP_PAUSE_SECONDS = 0.15

  attr_accessor :work_coordinator

#!!!!!The 'app_name' (call it '.*_category'?) needs to be stored in
#!!!!!a session. It shouldn't be in a server-side object.
=begin
A client needs to keep track of its client-session-id. When it first
"logs in", the server will give it a new client-session-id. Then it
(the client) will use that id to send requests to the server.
The client-session object will be stored in redis. The client can
send multiple requests to the server using the same
session id. When the client "logs off", that session-id/object will
be destroyed. Will probably need to implement a time-out: If the
server has not heard a request with a particular client-session-id
for <n> seconds, void the session by destroying the session-id/object.

The session-id or session object will need to be added as an
attribute to RedisBasedDataManager (and perhaps RedisSTodoManager).
[Maybe not: RedisBasedDataManager already has 'app_name' and 'user',
which is probably enough.]
Each work-server process will be handling a request for one client at a time
and will have the client's session-id and its own
RedisBasedDataManager instance. So the work-server will always perform
its "current response actions" tied to a specific session-id/user.

The client (such as STodoCliREPL) will need to begin by requesting a
'session_id' and/or ClientSession, which it will continue to use until
the user says to end it.
The server, of course needs to respond to this request. This should
probably be a publish/(request from client)/subscribe(response from
server) situation.
=end

#!!!to-do: formalize/fix:
TESTING = true

  def initialize
    Configuration.service_name = 'main-server'
    Configuration.debugging = false
    config = Configuration.instance
    app_config = config.app_configuration
    if TESTING then
      # (same-process version for testing)
      self.work_coordinator = Worker.new(config)
    else
      self.work_coordinator = WorkCoordinator.new(config)
    end
    initialize_pubsub_broker(app_config)
    super(SERVER_REQUEST_CHANNEL)
  end

  ##### Hook methods (called within infinite loop)

  def process(args = nil)
    subscribe do
      work_coordinator.delegate_request(last_message)
    end
  end

end
