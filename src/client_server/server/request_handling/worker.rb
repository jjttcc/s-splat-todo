require 'publisher'
require 'stodo_services_constants'
require 'request'

class Worker < Publisher
  include STodoServicesConstants

  public

  def process_request(request_object_key)
    request = message_broker.object(request_object_key)
    puts "request: #{request.inspect}"
  end

  private

  attr_accessor :message_broker

  def initialize(config)
    self.message_broker = config.application_message_broker
#!!!binding.irb
#!!!message_broker.set_object('test', Request.new)
    initialize_pubsub_broker(config)
    super(SERVER_RESPONSE_CHANNEL)
  end

end
