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
    admin_broker.retrieved_set(pattern)
  end

  # The list of all log keys for the current user.
  def log_key_list(criteria)
    # Note: 'criteria' is ignored due to potential security issues.
    # If "admin"-privilege-capability is added, 'criteria' might be used
    # if the user is an administrator.
    admin_broker.retrieved_set(config.user)
  end

  # The log messages associated with 'key'.
  def log_messages(key = "*")
    if key.nil? || key.empty? then
      key = '*'
    end
    admin_redis_log.contents(key)
  end

  private

  attr_writer :log, :admin_redis_log, :log_key
  # object used to store meta info about logging:
  attr_accessor :admin_broker
  attr_accessor :config

  # Initialize public attributes: 'log_key', 'admin_redis_log', 'log'
  # Initialize private attributes: 'admin_broker'
  # Set 'log_key' to "#{service_name}.#{<yyyymmdd>.<hhmmss>.<microseconds>}"
  # Add 'log_key' to the "#{service_name}-entries" queue.
  # Add 'service_name' to the set with the key SERVICE_NAMES_KEY if it is
  # not already in the set.
  pre :service_name_exists do |sname| ! sname.nil? end
  def initialize(service_name, config, debugging)
    init_config(config)
    self.log_key = log_key_for(service_name, config)
    # Set up to use the redis database for admin logging.
    self.admin_redis_log =
      MessageBrokerConfiguration.admin_message_log(log_key)
    self.admin_broker =
      MessageBrokerConfiguration.administrative_message_broker
    register_log_key(service_name, config, log_key)
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

=begin
#!!!!!Possible change to make logs easier to retrieve:
#!!!!!  Add a request-id, reqid, for this operation and somehow make it
#!!!!!  available to the user so that she can use reqid to retrieve the
#!!!!!  log entries for this particular operation. Add the reqid to
#!!!!!  log_key. Since log_key will be saved in:
#    admin_broker.queue_messages("...#{service_name}-entries", log_key)
#!!!!!  the key for the log entries for this request can be found by
#!!!!!  looking backwards in the queue to find the right key based on reqid.
#!!!!!  Or, perhaps use reqid as a hash key to store the associated log_key.
#!!!!!  In that case, reqid may not need to be part of log_key.
=end

  # (!!!Experiment!!!)
  # Set config attribute to 'config'.
  # Set config.request_id if 'current_request_id' exists.
  def init_config(config)
    self.config = config
    reqid = current_request_id
    if reqid then
      config.request_id = reqid
    end
  end

  def current_request_id
    nil
  end

  def log_key_for(service_name, config)
    date_time = Time.now.strftime("%Y%m%d.%H%M%S.%9N")
    result = "#{config.user}.#{service_name}.#{date_time}"
  end

  # Register the new 'log_key' as a stream key associated with
  # Register the new 'log_key' as a stream key by adding it to a set whose
  # key, k, is "#{config.user}.#{service_name}". And register that k as a
  # member of a set whose key is config.user.
  def register_log_key(service_name, config, log_key)
    key = "#{config.user}.#{service_name}"
    reqid = current_request_id
    if reqid then
      key = "#{reqid}.#{key}"
    end
    if ! admin_broker.set_has(config.user, key) then
      admin_broker.append_to_set(config.user, key)
    end
    admin_broker.append_to_set(key, log_key)
  end

end
