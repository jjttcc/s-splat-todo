require 'redis'
require 'redis_message_broker'
require 'redis_pub_sub_broker'
require 'redis_error_log'
require 'redis_log_reader'
require 'broker_authentication_data'

class MessageBrokerConfiguration
  include Contracts::DSL

  public  ###  Constants

  auth = BrokerAuthenticationData.new

  # redis application and administration ports
  REDIS_APP_PORT, REDIS_ADMIN_PORT = 6379, 26379
  # redis authentication info
  REDIS_PW = auth.broker_password
  # Default keys for logs
  DEFAULT_KEY, DEFAULT_ADMIN_KEY = 'tat', 'tat-admin'

  public

  # Broker for regular application-related messaging
  def self.application_message_broker
    redis = Redis.new(port: REDIS_APP_PORT, password: REDIS_PW)
    RedisMessageBroker.new(redis)
  end

  # Broker for administrative-level messaging
  def self.administrative_message_broker
    redis = Redis.new(port: REDIS_ADMIN_PORT, password: REDIS_PW)
    RedisMessageBroker.new(redis)
  end

  # Broker application-related publish/subscribe-based messaging
  def self.pubsub_broker
    redis = Redis.new(port: REDIS_APP_PORT, password: REDIS_PW)
    RedisPubSubBroker.new(redis)
  end

  # General message-logging object
  def self.message_log(key = DEFAULT_KEY)
    if key.nil? then
      key = DEFAULT_KEY
    end
    RedisLog.new(redis_port: REDIS_APP_PORT, redis_pw: REDIS_PW, key: key)
  end

  # Administrative message-logging object
  def self.admin_message_log(key = DEFAULT_ADMIN_KEY)
    if key.nil? then
      key = DEFAULT_ADMIN_KEY
    end
    RedisLog.new(redis_port: REDIS_ADMIN_PORT, redis_pw: REDIS_PW, key: key)
  end

  # Error log using the messaging system
  def self.message_based_error_log
    RedisErrorLog.new(redis_port: REDIS_APP_PORT, redis_pw: REDIS_PW)
  end

  def self.log_reader
    RedisLogReader.new(redis_port: REDIS_APP_PORT, redis_pw: REDIS_PW)
  end

  def self.admin_log_reader
    RedisLogReader.new(redis_port: REDIS_ADMIN_PORT, redis_pw: REDIS_PW)
  end

end
