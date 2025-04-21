require 'redis'
require 'redis_stream_facilities'
require 'message_log'

class RedisLog
  include Contracts::DSL, RedisStreamFacilities, MessageLog

  public

  #####  Access

  DEFAULT_EXPIRATION_SECS = 24 * 3600 * 365

  attr_reader   :key, :port
  attr_accessor :expiration_secs

  # contents of the log with key 'skey' - empty array if the log is empty
  # or no log exists with key 'skey'
  def contents(skey = self.key, count = nil)
    result = []
    if redis.exists(skey) > 0 && redis.type(skey) == "stream" then
      if count.nil? then
        result = redis.xrange(skey)
      else
        result = redis.xrange(skey, count)
      end
    end
    result
  end

  #####  Basic operations

  def send_message(log_key: key, tag:, msg:)
    redis.xadd(log_key, {tag => msg})
    redis.expire(log_key, expiration_secs)
  end

  def send_messages(log_key: key, messages_hash:)
    redis.xadd(log_key, messages_hash)
    redis.expire(log_key, expiration_secs)
  end

  #####  State-changing operations

  def change_key(new_key)
    self.key = new_key
  end

  protected

  attr_reader :redis

  private

  attr_writer :redis, :key, :port

  # Initialize with the Redis-port, logging key, and, if supplied, the
  # number of seconds until each logged message is set to expire (which
  # defaults to DEFAULT_EXPIRATION_SECS).
  # precondition: redis_port != nil
  # precondition: key != nil
  # precondition: redis_pw != nil
  # postcondition self.redis != nil
  def initialize(redis_port:, redis_pw:, key:,
                 expire_secs: DEFAULT_EXPIRATION_SECS)
    init_facilities(redis_port, redis_pw)
    self.key = key
    self.port = redis_port
    self.expiration_secs = expire_secs
  end

end
