require 'message_broker_configuration'
require 'redis_logger_device'

# redis-based logging configuration
# Note: The global variable $log is set to a redis-based Logger instance
# when RedisLog.new is called.
# For log message recovery, adds self.log_key, in the constructor, to the
# list whose key is:
#   "#{self.service_name}-entries"
class RedisLogConfig
  include Contracts::DSL

  # The global logging (Logger) instance
  attr_reader :log
  # "administration" RedisLog instance used by 'log'
  attr_reader :admin_redis_log
  # The stream key used for logging in 'admin_redis_log'
  attr_reader :log_key

  private

  attr_writer :log, :admin_redis_log, :log_key
  attr_accessor :admin_broker

  pre :service_name_exists do |sname| ! sname.nil? end
  def initialize(service_name, debugging)
    # Set up to use the redis database for admin logging.
    self.log_key = "#{service_name}#{$$}"
    self.admin_redis_log =
      MessageBrokerConfiguration.admin_message_log(log_key)
    self.admin_broker =
      MessageBrokerConfiguration.administrative_message_broker
    admin_broker.queue_messages("#{service_name}-entries", log_key)
    self.log = RedisLoggerDevice.new(admin_redis_log,
                                     admin_redis_log.key).logger
    $log = log
    if debugging then
      pw = ENV["REDISCLI_AUTH"]
      $redis = ApplicationConfiguration.redis
    end
  end
end
