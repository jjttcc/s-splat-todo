require 'redis'
require 'redis_stream_facilities'
require 'message_log'

class RedisLog
  include Contracts::DSL, RedisStreamFacilities, MessageLog

  public

  #####  Access

  DEFAULT_EXPIRATION_SECS = 24 * 3600 * 365

  attr_reader   :key
  attr_accessor :expiration_secs

  def contents(count: nil)
    redis_log.xrange(key, count)
  end

  #####  Basic operations

  def debug__send_message(log_key: key, tag:, msg:)
#binding.irb
    redis_log.set(log_key, tag + msg)
  end

  def send_message(log_key: key, tag:, msg:)
#binding.irb
    redis_log.xadd(log_key, {tag => msg})
#redis_log.xadd('different-key101', { "o" => "z" })
#added = redis.xread('logger_stream', '0-0', count: 2)
added = redis_log.xread(log_key, '0-0', count: 2)
puts added
    redis_log.expire(log_key, expiration_secs)
  end

  def send_messages(log_key: key, messages_hash:)
    redis_log.xadd(log_key, messages_hash)
    redis_log.expire(log_key, expiration_secs)
  end

  #####  State-changing operations

  def change_key(new_key)
    self.key = new_key
  end

#!!![debug]  protected
  public

  attr_reader :redis_log

  private

  attr_writer :redis_log, :key

  # Initialize with the Redis-port, logging key, and, if supplied, the
  # number of seconds until each logged message is set to expire (which
  # defaults to DEFAULT_EXPIRATION_SECS).
  pre :port_exists do |hash| hash[:redis_port] != nil end
  pre :key_exists  do |hash| hash[:key] != nil end
  post :redis_lg  do self.redis_log != nil end
  def initialize(redis_port:, redis_pw:, key:,
                 expire_secs: DEFAULT_EXPIRATION_SECS)
    init_facilities(redis_port, redis_pw)
    self.key = key
    self.expiration_secs = expire_secs
  end

end
