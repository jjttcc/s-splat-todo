require 'ruby_contracts'
require 'method_source'

module Subscription
  include Contracts::DSL

  public

  #####  Access

  # The default 'channel' on which to publish
  attr_reader :default_subscription_channel

  # The last message received via the subscription
  attr_reader :last_message

  # Publish/Subscribe broker
  attr_reader :pubsub_broker

  #####  State-changing operations

  # Subscribe to 'channel' until the first message is received, calling the
  # block (if it is provided) after setting 'last_message' to the message.
  # Then (after the first message is received & processed) unsubscribe.
  pre  :pubsub_broker do ! self.pubsub_broker.nil? end
  post :last_message  do ! last_message.nil? end
  def subscribe(channel = default_subscription_channel, &block)
    pubsub_broker.subscribe(channel, subs_callbacks) do
      @last_message = pubsub_broker.last_message
      msg = "#{self.class}] received '#{@last_message}' (stack:\n" +
        caller.join("\n") + ")"
      log_messages(channel: msg)
      if block != nil then
        block.call
      end
    end
  end

  # Subscribe to 'channel' until the first message is received, calling the
  # block (if it is provided) after setting 'last_message' to the message.
  # Then (after the first message is received & processed) unsubscribe.
  pre  :pubsub_broker do ! self.pubsub_broker.nil? end
  post :last_message  do ! last_message.nil? end
  def subscribe_once(channel = default_subscription_channel, &block)
    pubsub_broker.subscribe(channel, subs_callbacks, true) do
      @last_message = pubsub_broker.last_message
      msg = "#{self.class}] received '#{@last_message}' (stack:\n" +
        caller.join("\n") + ")"
      log_messages(channel: msg)
      if block != nil then
        block.call
      end
    end
  end

  #####  Class invariant

  # pubsub_broker exists.
  def invariant
    pubsub_broker != nil
  end

  protected

  # Callbacks (Hash of lambdas) for subscription events - initialize upon
  # object creation if needed:
  attr_reader :subs_callbacks

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
