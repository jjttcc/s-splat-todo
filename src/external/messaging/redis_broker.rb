require 'ruby_contracts'

# Basic Redis brokering facilities
module RedisBroker
  include Contracts::DSL

  public

  # The Redis client 'handle'
  attr_accessor :redis

  public  ## Class invariant

  def invariant
    redis != nil && redis.ping != nil && redis.ping.length > 0
  end

  protected  ###  Initialization

  pre  :rclient do |rc| ! (rc.nil? || rc.ping.nil?) && rc.ping.length > 0 end
  post :redis_set do invariant end
  def initialize(redis_client)
    @redis = redis_client
  end

end
