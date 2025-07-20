require 'ruby_contracts'
require 'application_configuration'
require 'redis_logger_device'

# redis-based database configuration
class RedisDBConfig
  include Contracts::DSL

  public  ### Attributes

  # The RedisBasedDataManager instance
  attr_reader :data_manager

  public  ### Look-up services

  private

  attr_accessor :config, :data_broker
  attr_writer :data_manager

  pre :config_exists do |config| ! config.nil? end
  def initialize(config, skip_global_set_add: false)
    self.config = config
    broker = ApplicationConfiguration.application_message_broker

    self.data_manager = RedisBasedDataManager.new(broker, config.user,
                                                 config.app_name, skip_global_set_add: skip_global_set_add)
  end

end
