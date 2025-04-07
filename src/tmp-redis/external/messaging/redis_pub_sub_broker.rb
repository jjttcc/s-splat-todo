require 'redis_broker'

# Publish/subscribe broker implemented using Redis
class RedisPubSubBroker
  include Contracts::DSL, RedisBroker

  public

  # The last message received via the subscription
  attr_reader :last_message

  public

  # Publish 'message' on the channel identified by 'channel'.
  pre :redis_exists do ! redis.nil? end
  pre :ch_and_msg   do |ch, msg| ! (ch.nil? || msg.nil?) end
  def publish(channel, message)
    redis.publish channel, message
  end

  # Subscribe to 'channel' until the first message is received, calling the
  # block (if it is provided), after setting 'last_message' to the message.
  # Then (after the first message is received & processed) unsubscribe.
  # If provided, the 'callbacks' argument is a hash table that - optionally -
  # contains one or more lambdas, indexed by the keys :preproc, :process,
  # :postproc, where the corresponding value, respectively is called:
  #   - before the subscription occurs (preproc).
  #   - when the first message is received, after 'block' is invoked (process).
  #   - after the subscription is ended (postproc).
  pre  :redis_exists do ! redis.nil? end
  pre  :channel      do |channel| ! channel.nil? end
  pre  :cbs_hash     do |ch, cbs| implies(cbs != nil, cbs.is_a?(Hash)) end
  post :last_message do ! last_message.nil? end
  def subscribe_once(channel, callbacks = nil, &block)
    preprocessor, processor, postprocessor = nil, nil, nil
    if callbacks != nil then
      preprocessor ||= callbacks[:preproc]
      processor ||= callbacks[:process]
      postprocessor ||= callbacks[:postproc]
    end
    if preprocessor != nil then
      preprocessor.call
    end
    redis.subscribe channel do |on|
      on.message do |channel, message|
        @last_message = message
        if block != nil then
          block.call
        end
        if processor != nil then
          processor.call
        end
        redis.unsubscribe channel
      end
    end
    if postprocessor != nil then
      postprocessor.call
    end
  end

end
