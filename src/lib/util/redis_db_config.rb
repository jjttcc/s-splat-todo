require 'ruby_contracts'
require 'application_configuration'
require 'redis_logger_device'
require 'transaction_manager'

# redis-based database configuration
class RedisDBConfig
  include Contracts::DSL
#!!!!!Is ConfigTools needed?:
  include ConfigTools

  public  ### Attributes

  #?????????????#
#!!!!rm?:  attr_reader :transaction_manager
  #?????????????#
  # The RedisBasedDataManager instance
  attr_reader :data_manager

  public  ### Look-up services

  private

  #?????????????#
#!!!!rm?:  attr_writer :admin_broker, :transaction_manager
  attr_accessor :config, :data_broker
  #?????????????#
  attr_writer :data_manager

  # Initialize public attributes: ???, 'data_manager'.
  # ????Initialize private attributes: 'admin_broker'???
  # Add 'service_name' to the set with the key SERVICE_NAMES_KEY if it is
  # not already in the set.
  pre :config_exists do |config| ! config.nil? end
  def initialize(config)
    self.config = config
    broker = ApplicationConfiguration.application_message_broker
    ###Note: Will need to add config.app_name:
    self.data_manager = RedisBasedDataManager.new(broker, config.user)
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
