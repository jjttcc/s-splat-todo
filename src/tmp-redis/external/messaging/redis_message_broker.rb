require 'redis_broker'
require 'oj'

# Message-broker interface to Redis
class RedisMessageBroker
  include Contracts::DSL, RedisBroker

  public  ###  Access

  # The message previously added via 'set_message(key, msg)'
  def retrieved_message(key)
    result = redis.get key
    result
  end

  # The set previously built via 'replace_set(key, args)' and/or
  # 'add_set(key, args)'
  post :result_exists do |result| ! result.nil? && result.is_a?(Array) end
  def retrieved_set(key)
    result = redis.smembers key
    result
  end

  # The next element (head) in the queue with key 'key' (typically,
  # inserted via 'queue_messages')
  post :nil_if_empty do |res, key| implies(queue_count(key) == 0, res.nil?) end
  def queue_head(key)
    result = nil
    array = redis.lrange(key, -1, -1)
    if ! array.empty? then
      result = array.first
    end
    result
  end

  # The last element (tail) in the queue with key 'key' (typically,
  # inserted via 'queue_messages')
  post :nil_if_empty do |res, key| implies(queue_count(key) == 0, res.nil?) end
  def queue_tail(key)
    result = nil
    array = redis.lrange(key, 0, 0)
    if ! array.empty? then
      result = array.first
    end
    result
  end

  # All elements of the queue identified with 'key', in their original
  # order - The queue's state is not changed.
  def queue_contents(key)
    # ('.reverse' because the list representation reverses the elements' order.)
    redis.lrange(key, 0, -1).reverse
  end

  # The object stored with 'key' - nil if there is no object at 'key'
  def object(key, admin = false)
    result = nil
    guts = retrieved_message(key)
    if guts != nil then
      result = Oj.load(guts)
    end
    result
  end

  public  ###  Status report

  # Is the server alive?
  def is_alive?
    result = redis.ping != nil
    result
  rescue
    false
  end

  # Does the object with key 'key' exist?
  def exists(key)
    redis.exists(key) > 0
  end

  # The number of members in the set identified by 'key'
  post :result_exists do |result| ! result.nil? && result >= 0 end
  def cardinality(key)
    result = redis.scard key
    result
  end

  # The count (size) of the queue with key 'key'
  def queue_count(key)
    redis.llen(key)
  end

  # Does the queue with key 'key' contain at least one instance of 'value'?
  # Note: This query is relatively expensive.
  def queue_contains(key, value)
    redis.lrange(key, 0, -1).include?(value)
  end

  public  ###  Element change

  # Set (insert) a keyed message
  # If 'expire_secs' is not nil, set the time-to-live for 'key' to
  # expire_secs seconds.
  pre :sane_expire do |k, m, exp|
    implies(exp != nil, exp.is_a?(Numeric) && exp >= 0) end
  def set_message(key, msg, expire_secs = nil)
    if @@redis_debug then
      puts "set_message - calling redis.set with #{key}, " +
        "#{msg}, #{expire_secs}, redis: #{redis}"
    end
    if ! expire_secs.nil? then
      redis.set key, msg, :ex => expire_secs
    else
      redis.set key, msg
    end
    if @@redis_debug then
      puts "[set_message - survived redis.set!]"
    end
  end

  # Set (insert) 'object' with 'key'
  # If 'expire_secs' is not nil, set the time-to-live for 'key' to
  # expire_secs seconds.
  pre :sane_expire do |k, m, exp|
    implies(exp != nil, exp.is_a?(Numeric) && exp >= 0) end
  # post :object_stored do |result, key, o|
  #   object(key) != nil && object(key) === o end
  def set_object(key, object, expire_secs = nil)
    serialized_object = Oj.dump(object)
    set_message(key, serialized_object, expire_secs)
  end

  # Add 'msgs' (a String, if 1 message, or an array of Strings) to the end of
  # the queue (implemented as a list) with key 'key'.
  # If 'expire_secs' is not nil, set the time-to-live for the set to
  # 'expire_secs' seconds.
  # Return the resulting size of the queue.
  pre :sane_expire do |k, m, exp|
    implies(exp != nil, exp.is_a?(Numeric) && exp >= 0) end
  def queue_messages(key, msgs, expire_secs = nil)
    result = redis.lpush(key, msgs)
    if expire_secs != nil then
      redis.expire key, expire_secs
    end
    result
  end

  # Move the next (head) element from the queue @ key1 to the tail of the
  # queue @ key2.  If key1 == key2, move the head to the tail of the same
  # queue.
  pre :keys_exist do |key1, key2| ! (key1.nil? || key2.nil?) end
  def move_head_to_tail(key1, key2)
    ttl = -3
    if ! redis.exists(key2) && redis.exists(key1) then
      ttl = redis.ttl(key1)
    end
    redis.rpoplpush(key1, key2)
    if ttl > 0 then
      # queue @ key2 is new - set its time-to-live to that of key1.
      redis.expire(key2, ttl)
    end
  end

  # Add, with 'key', the specified set with items 'args'.  If the set
  # (with 'key') already exists, simply add to the set any items from 'args'
  # that aren't already in the set.
  # If 'expire_secs' is not nil, set the time-to-live for the set to
  # 'expire_secs' seconds.
  # Return the resulting count value (of items actually added) from Redis.
  pre :sane_expire do |k, a, exp|
    implies(exp != nil, exp.is_a?(Numeric) && exp >= 0) end
  def add_set(key, args, expire_secs = nil)
    result = redis.sadd key, args
    if expire_secs != nil then
      redis.expire key, expire_secs
    end
    result
  end

  # Add, with 'key', the specified set with items 'args'.  If the set
  # (with 'key') already exists, remove the old set first before creating
  # the new one.
  # Return the resulting count value (of items actually added) from Redis.
  def replace_set(key, args)
    redis.del key
    redis.sadd key, args
  end

  public  ###  Removal

  # Remove members 'args' from the set specified by 'key'.
  def remove_from_set(key, args)
    redis.srem key, args
  end

  # Remove the next-element/head (i.e., dequeue) of the queue with key 'key'
  # (typically, inserted via 'queue_messages').  Return the value of that
  # element - nil if the queue is empty or does not exist.
  def remove_next_from_queue(key)
    redis.rpop(key)
  end

  # Remove all occurrences of 'value' from the queue with key 'key'.
  # Return the number of removed elements.
  def remove_from_queue(key, value)
    redis.lrem(key, 0, value)
  end

  # Delete the object (message inserted via 'set_message', set added via
  # 'add_set', or etc.) with the specified key.
  def delete_object(key)
    redis.del key
  end

  protected

  @@redis_debug = false

  EXP_KEY = :ex
#!!!  EXP_KEY = "ex"

end
