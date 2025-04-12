
module RedisStreamFacilities
  include Contracts::DSL

  public

  FIRST_ID, LAST_ID = '0-0', '$'

  EARLIEST_ID, LATEST_ID = '-', '+'

  protected

  DEFAULT_OBJECT_KEY = :redis_object_key

  attr_reader :redis_log, :object_key

  def init_facilities(redis_port, redis_pw)
    init_redis(redis_port, redis_pw)
    @object_key = DEFAULT_OBJECT_KEY
  end

  private

  attr_writer :redis_log

  # Initialize with the Redis-port, logging key, and, if supplied, the
  # number of seconds until each logged message is set to expire (which
  # defaults to DEFAULT_EXPIRATION_SECS).
  pre :port_exists do |redis_port| redis_port != nil end
  post :redis_lg  do self.redis_log != nil end
  def init_redis(redis_port, redis_pw)
    self.redis_log = Redis.new(port: redis_port, password: redis_pw)
  end

end
