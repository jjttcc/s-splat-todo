require 'ruby_contracts'

module Publication
  include Contracts::DSL

  public

  # The default 'channel' on which to publish
  attr_reader :default_publishing_channel

  # Publish/Subscribe broker
  attr_reader :pubsub_broker

  pre :pubsub_broker do invariant end
  pre :pub_msg do |message| ! message.nil? end
  def publish(message, channel = default_publishing_channel)
    msg = "#{self.class}] published '#{message}' (stack:\n" +
      caller.join("\n") + ")"
    pubsub_broker.publish channel, message
    log_messages(channel: msg)
  end

  ##### class invariant

  # pubsub_broker exists.
  def invariant
    pubsub_broker != nil
  end

  protected

  ##### Hook methods

  def log_messages(messages_hash)
    ## Redefine for debug/info logging.
  end

  #####  Initialization

  pre  :config_exists do |configuration| configuration != nil end
  post :broker_set do pubsub_broker != nil end
  def initialize_pubsub_broker(configuration)
    @pubsub_broker = configuration.pubsub_broker
  end

end
