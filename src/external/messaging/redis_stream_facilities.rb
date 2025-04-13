
module RedisStreamFacilities
  include Contracts::DSL

  public

  FIRST_ID, LAST_ID = '0-0', '$'

  EARLIEST_ID, LATEST_ID = '-', '+'

  protected

  DEFAULT_OBJECT_KEY = :redis_object_key

  attr_reader :redis, :object_key

  def init_facilities(redis_port, redis_pw)
    init_redis(redis_port, redis_pw)
    @object_key = DEFAULT_OBJECT_KEY
  end

  private

  attr_writer :redis

  # Initialize with the Redis-port, logging key, and, if supplied, the
  # number of seconds until each logged message is set to expire (which
  # defaults to DEFAULT_EXPIRATION_SECS).
  pre :port_exists do |redis_port| redis_port != nil end
  post :redis_lg  do self.redis != nil end
  def init_redis(redis_port, redis_pw)
    self.redis = Redis.new(port: redis_port, password: redis_pw)
  end

end
