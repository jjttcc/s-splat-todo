require 'publisher'

# Objects that represent a work server running in a separate process
class WorkServerProcess < Publisher

  public

  # Notify the worker process via publication of new request.
  def notify_worker(request_object_key)
    publish(request_object_key)
  end

  attr_accessor :server_id, :child_pid

  private

  def initialize(server_id, child_pid, configuration)
    self.server_id = server_id
    self.child_pid = child_pid
    # Set Publisher channel
    super(server_id)
    initialize_pubsub_broker(configuration)
  end

end
