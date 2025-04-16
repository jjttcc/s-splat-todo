require 'message_broker_configuration'
require 'redis_logger_device'

# redis-based logging configuration
# Note: The global variable $log is set to a redis-based Logger instance
# when RedisLog.new is called.
# For log message recovery, adds self.log_key, in the constructor, to the
# list whose key is:
#   "#{self.service_name}-entries"
class RedisLogConfig
  include Contracts::DSL, ConfigTools

  public  ### Attributes

  # The global logging (Logger) instance
  attr_reader :log
  # "administration" RedisLog instance used by 'log'
  attr_reader :admin_redis_log
  # The stream key used for logging in 'admin_redis_log'
  attr_reader :log_key

  public  ### Look-up services

  # All administration service names
  def service_names
    admin_broker.set_members(SERVICE_NAMES_KEY)
  end

  # All "stream keys" used for logging that match 'pattern' - all keys if
  # 'pattern' is empty or nil
  def log_keys(pattern = "*")
    if pattern.nil? || pattern.empty? then
      pattern = '*'
    end
    admin_broker.keys(pattern)
  end

  def log_messages(key = "*")
    if key.nil? || key.empty? then
      key = '*'
    end
    admin_redis_log.contents(skey: key)
  end

  private

  attr_writer :log, :admin_redis_log, :log_key
  # object used to store meta info about logging:
  attr_accessor :admin_broker

  # Initialize public attributes: 'log_key', 'admin_redis_log', 'log'
  # Initialize private attributes: 'admin_broker'
  # Set 'log_key' to "#{service_name}.#{<yyyymmdd>.<hhmmss>.<microseconds>}"
  # Add 'log_key' to the "#{service_name}-entries" queue.
  # Add 'service_name' to the set with the key SERVICE_NAMES_KEY if it is
  # not already in the set.
  pre :service_name_exists do |sname| ! sname.nil? end
  def initialize(service_name, debugging)
    # Set up to use the redis database for admin logging.
    date_time = Time.now.strftime("%Y%m%d.%H%M%S.%6N")
    self.log_key = "#{service_name}.#{date_time}"
    self.admin_redis_log =
      MessageBrokerConfiguration.admin_message_log(log_key)
    self.admin_broker =
      MessageBrokerConfiguration.administrative_message_broker
    # Register the new 'log_key' as a stream key associated with service_name:
    admin_broker.queue_messages("#{service_name}-entries", log_key)
    if
      ! admin_broker.exists(SERVICE_NAMES_KEY) ||
      ! admin_broker.set_has(SERVICE_NAMES_KEY, service_name)
    then
      # Add 'service_name' to the list of "stodo" services:
      admin_broker.add_set(SERVICE_NAMES_KEY, service_name)
    end
    self.log = RedisLoggerDevice.new(admin_redis_log,
                                     admin_redis_log.key).logger
    $log = log
    if debugging then
      pw = ENV["REDISCLI_AUTH"]
      $redis = ApplicationConfiguration.redis
    end
  end
end
