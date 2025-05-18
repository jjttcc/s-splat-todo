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
  def initialize(config)
    self.config = config
    broker = ApplicationConfiguration.application_message_broker
    ###Note: Will need to add config.app_name:
    self.data_manager = RedisBasedDataManager.new(broker, config.user,
                                                 config.app_name)
  end

end
