# Facilities - utility methods, etc. - related to use of a message broker
# Note: 'initialize_message_brokers' must be called before calling any other
# public method of this interface; and a 'log' method (which is called by
# 'initialize_message_brokers') that returns an object that performs logging
# must be defined
module MessagingFacilities
  include Contracts::DSL

  public

  #####  Access

  DEFAULT_OBJECT_EXPIRATION = 24 * 3600

  attr_accessor :broker, :admin_broker, :object_expiration_seconds

  #####  Message query/retrieval

  # The message previously added via 'set_message(key, msg)'
  # If 'admin', use the administrative message broker instead of the
  # regular one.
  # pre :brokers_exist do ! (broker.nil? || admin_broker.nil?) end
  def retrieved_message(key, admin = false)
    if admin then
      result = admin_broker.retrieved_message key
    else
      result = broker.retrieved_message key
    end
    result
  end

  # The set previously built via 'replace_set(key, args)' and/or
  # 'add_set(key, args)'
  post :result_existsB do |result| ! result.nil? && result.is_a?(Array) end
  def retrieved_set(key, admin = false)
    if admin then
      admin_broker.retrieved_set key
    else
      broker.retrieved_set key
    end
  end

  # The next element (head) in the queue with key 'key' (typically,
  # inserted via 'queue_messages')
  post :nil_if_empty do |res, key| implies(queue_count(key) == 0, res.nil?) end
  def queue_head(key, admin = false)
    if admin then
      admin_broker.queue_head key
    else
      broker.queue_head key
    end
  end

  # The last element (tail) in the queue with key 'key' (typically,
  # inserted via 'queue_messages')
  post :nil_if_empty do |res, key| implies(queue_count(key) == 0, res.nil?) end
  def queue_tail(key, admin = false)
    if admin then
      admin_broker.queue_tail key
    else
      broker.queue_tail key
    end
  end

  # All elements of the queue identified with 'key', in their original
  # order - The queue's state is not changed.
  def queue_contents(key, admin = false)
    if admin then
      admin_broker.queue_contents key
    else
      broker.queue_contents key
    end
  end

  # The object stored with 'key' - nil if there is no object at 'key'
  pre  :key_exists do |key| key != nil end
  def object(key, admin = false)
    if admin then
      admin_broker.object key
    else
      broker.object key
    end
  end

  #####  Message status queries

  # The number of members in the set identified by 'key'
  post :result_existsC do |result| ! result.nil? && result >= 0 end
  def cardinality(key, admin = false)
    if admin then
      admin_broker.cardinality key
    else
      broker.cardinality key
    end
  end

  # The count (size) of the queue with key 'key'
  def queue_count(key, admin = false)
    if admin then
      admin_broker.queue_count key
    else
      broker.queue_count key
    end
  end

  #####  Boolean queries

  # Does the object with key 'key' exist?
  def exists(key)
    if admin then
      admin_broker.exists key
    else
      broker.exists key
    end
  end

  # Does the queue with key 'key' contain at least one instance of 'value'?
  # Note: This query is relatively expensive.
  def queue_contains(key, value, admin = false)
    if admin then
      admin_broker.queue_contains key, value
    else
      broker.queue_contains key, value
    end
  end

  #####  Message sending, manipulation

  # Set (insert) a keyed message.
  # If 'expire_secs' is not nil and if expiration is supported by the
  # message broker, set the time-to-live for 'key' to 'expire_secs' seconds.
  pre :sane_expire do |k, m, exp|
    implies(exp != nil, exp.is_a?(Numeric) && exp >= 0) end
  def set_message(key, msg, expire_secs = nil, admin = false)
    if admin then
      admin_broker.set_message key, msg, expire_secs
    else
      broker.set_message key, msg, expire_secs
    end
  end

  # Set (insert) 'object' with 'key' with the specified expiration time.
  pre :sane_expire do |k, m, exp|
    implies(exp != nil, exp.is_a?(Numeric) && exp >= 0) end
  def set_object(key, object, expire_secs = self.object_expiration_seconds,
                admin = false)
    if admin then
      admin_broker.set_object key, object, expire_secs
    else
      broker.set_object key, object, expire_secs
    end
  end

  # Add 'msgs' (a String, if 1 message, or an array of Strings) to the end of
  # the queue (implemented as a list) with key 'key'.
  # If 'expire_secs' is not nil and if expiration is supported by the
  # message broker, set the time-to-live for 'key' to 'expire_secs' seconds.
  # Return the resulting size of the queue.
  pre :sane_expire do |k, m, exp|
    implies(exp != nil, exp.is_a?(Numeric) && exp >= 0) end
  def queue_messages(key, msgs, expire_secs = nil, admin = false)
    if admin then
      result = admin_broker.queue_messages key, msgs, expire_secs
    else
      result = broker.queue_messages key, msgs, expire_secs
    end
    result
  end

  # Move the next (head) element from the queue @ key1 to the tail of the
  # queue @ key2.  If key1 == key2, move the head to the tail of the same
  # queue.
  pre :keys_exist do |key1, key2| ! (key1.nil? || key2.nil?) end
  def move_head_to_tail(key1, key2, admin = false)
    if admin then
      admin_broker.move_head_to_tail key1, key2
    else
      broker.move_head_to_tail key1, key2
    end
  end

  # Rotate the queue @ key such that the former head is moved to the tail of
  # the queue and former second element becomes the head, etc.
  # Note: This operation [rotate_queue(key)] is the same as calling:
  #   move_head_to_tail(key, key)
  pre :key_exists do |key| ! key.nil? end
  def rotate_queue(key, admin = false)
    move_head_to_tail(key, key, admin)
  end

  # Add, with 'key', the specified set with items 'args'.  If the set
  # (with 'key') already exists, simply add to the set any items from 'args'
  # that aren't already in the set.
  # If 'expire_secs' is not nil and if expiration is supported by the
  # message broker, set the time-to-live for 'key' to 'expire_secs' seconds.
  pre :sane_expire do |k, a, exp|
    implies(exp != nil, exp.is_a?(Numeric) && exp >= 0) end
  def add_set(key, args, expire_secs = nil, admin = false)
    if admin then
      admin_broker.add_set key, args, expire_secs
    else
      broker.add_set key, args, expire_secs
    end
  end

  # Add, with 'key', the specified set with items 'args'.  If the set
  # (with 'key') already exists, remove the old set first before creating
  # the new one.
  def replace_set(key, args, admin = false)
    if admin then
      admin_broker.replace_set key, args
    else
      broker.replace_set key, args
    end
  end

  #####  Message-removal operations

  # Remove members 'args' from the set specified by 'key'.
  def remove_from_set(key, args, admin = false)
    if admin then
      admin_broker.remove_from_set key, args
    else
      broker.remove_from_set key, args
    end
  end

  # Remove the next-element/head (i.e., dequeue) of the queue with key 'key'
  # (typically, inserted via 'queue_messages').  Return the value of that
  # element - nil if the queue is empty or does not exist.
  def remove_next_from_queue(key, admin = false)
    if admin then
      admin_broker.remove_next_from_queue key
    else
      broker.remove_next_from_queue key
    end
  end

  alias_method :dequeue, :remove_next_from_queue

  # Remove all occurrences of 'value' from the queue with key 'key'.
  # Return the number of removed elements.
  def remove_from_queue(key, value, admin = false)
    if admin then
      admin_broker.remove_from_queue key, value
    else
      broker.remove_from_queue key, value
    end
  end

  # Delete the object (message inserted via 'set_message', set added via
  # 'add_set', or etc.) with the specified key.
  def delete_object(key, admin = false)
    if admin then
      admin_broker.delete_object key
    else
      broker.delete_object key
    end
  end

  alias_method :delete_queue, :delete_object

  #####  Key-related utilities

  BOTTOM_KEY_INTEGER, TOP_KEY_INTEGER = 70_000, 99_999
  @@key_int_bank = []

  # The "next" randomly-generated integer value
  def next_key_integer
    if @@key_int_bank.empty? then
      bank_size = TOP_KEY_INTEGER - BOTTOM_KEY_INTEGER + 1
      @@key_int_bank =
        (BOTTOM_KEY_INTEGER...TOP_KEY_INTEGER).to_a.sample(bank_size)
    end
    @@key_int_bank.pop
  end

  # A new, "semi-random", key starting with 'base'
  def new_semi_random_key(base)
    base + next_key_integer.to_s
  end

  #####  Initialization

  pre  :config_exists do |configuration| configuration != nil end
  post :brokers_set do broker != nil && admin_broker != nil end
  def initialize_message_brokers(configuration)
    @broker = configuration.application_message_broker
    @admin_broker = configuration.administrative_message_broker
    @object_expiration_seconds = DEFAULT_OBJECT_EXPIRATION
  end

end
