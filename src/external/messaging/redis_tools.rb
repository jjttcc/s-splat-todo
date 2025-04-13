require 'ruby_contracts'

# General Redis-related utility functions
module RedisTools
  include Contracts::DSL

  # All current keys of type 'key_type' in the Redis database associated
  # with the Redis client instance referenced by 'redis_handle'
  pre  :args  do |t, rh| t != nil && rh != nil end
  post :array do |result| result != nil && result.is_a?(Array) end
  post :symbols do |result| result.all? { |k| k.is_a?(Symbol) } end
  def all_keys_of_type(key_type, redis_handle)
    result = []
    target_type = key_type.to_s
    keys = redis_handle.keys("*")
    result = keys.select do |k|
      redis_handle.type(k) == target_type
    end.map { |k| k.to_sym }
    result
  end

end
