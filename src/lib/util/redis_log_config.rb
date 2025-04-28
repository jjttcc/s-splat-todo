require 'application_configuration'
require 'redis_logger_device'
require 'transaction_manager'

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
  attr_reader :admin_log
  # The stream key used for logging in 'admin_log'
  attr_reader :log_key
  # Object used to store meta info about logging
  attr_reader :admin_broker
  attr_reader :transaction_manager

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
    admin_log.contents(key)
  end

  private

  attr_writer :log, :admin_log, :log_key, :admin_broker, :transaction_manager
  attr_accessor :config

  # Initialize public attributes: 'log_key', 'admin_log', 'log',
  # 'transaction_manager'.
  # Initialize private attributes: 'admin_broker'
  # Set 'log_key' to "#{service_name}.#{<yyyymmdd>.<hhmmss>.<microseconds>}"
  # Add 'log_key' to the "#{service_name}-entries" queue.
  # Add 'service_name' to the set with the key SERVICE_NAMES_KEY if it is
  # not already in the set.
  pre :service_name_exists do |sname| ! sname.nil? end
  def initialize(service_name, config, debugging)
    init_config(config)
    self.log_key = log_key_for(service_name)
    # Set up to use the redis database for admin logging.
    self.admin_log =
      ApplicationConfiguration.admin_message_log(log_key)
    self.admin_broker =
      ApplicationConfiguration.administrative_message_broker
    self.transaction_manager = TransactionManager.new(admin_broker, admin_log,
                                              config.user)
    register_log_key(service_name, log_key)
    if
      ! admin_broker.exists(SERVICE_NAMES_KEY) ||
      ! admin_broker.set_has(SERVICE_NAMES_KEY, service_name)
    then
      # Add 'service_name' to the list of "stodo" services:
      admin_broker.add_set(SERVICE_NAMES_KEY, service_name)
    end
    self.log = RedisLoggerDevice.new(admin_log, admin_log.key,
                                    transaction_manager).logger
    $log = log
    if debugging then
      pw = ENV["REDISCLI_AUTH"]
      $redis = ApplicationConfiguration.redis
    end
  end

  # Set config attribute to 'config'.
  def init_config(config)
    self.config = config
  end

  def log_key_for(service_name)
    date_time = TimeUtil.current_nano_date_time
    result = "#{config.user}.#{service_name}.#{date_time}"
  end

  # Register the new 'log_key' as a stream key by adding it to a set whose
  # key, k, is "#{config.user}.#{service_name}". And register that k as a
  # member of a set whose key is config.user.
  def register_log_key(service_name, log_key)
    key = "#{config.user}.#{service_name}"
    if ! admin_broker.set_has(config.user, key) then
      admin_broker.append_to_set(config.user, key)
    end
    admin_broker.append_to_set(key, log_key)
  end

end
