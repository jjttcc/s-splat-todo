PRODUCTION_VAR_NAME = 'STODO_PRODUCTION'
if $is_production_run.nil? then
  $is_production_run =  ENV.has_key?(PRODUCTION_VAR_NAME)
end

require 'utility_configuration'
require 'message_broker_configuration'
require 'time_util'

# Application-level/plug-in configuration
class ApplicationConfiguration
  include Contracts::DSL

  public

  #####  Constants

  # Number of seconds until the next "tradable-tracking cleanup" needs to
  # be performed:
  TRACKING_CLEANUP_INTERVAL = 61200

  #####  Constants - instance access

  def tracking_cleanup_interval
    TRACKING_CLEANUP_INTERVAL
  end

  #####  Access - objects

  attr_reader :log

  # An instance of Redis - mostly (or entirely) for debugging (class method)
  def self.redis
    MessageBrokerConfiguration::redis
  end

  # Broker for regular application-related messaging
  def application_message_broker
    MessageBrokerConfiguration::application_message_broker
  end

  # Broker for regular application-related messaging - class-method
  # version of the above
  def self.application_message_broker
    MessageBrokerConfiguration::application_message_broker
  end

  # Broker for administrative-level messaging
  def administrative_message_broker
    MessageBrokerConfiguration::administrative_message_broker
  end

  # Broker application-related publish/subscribe-based messaging
  def pubsub_broker
    MessageBrokerConfiguration::pubsub_broker
  end

  # General message-logging object
  def message_log(key = nil)
    MessageBrokerConfiguration::message_log(key)
  end

  # General message-logging object - class-method version of the above
  def self.message_log(key = nil)
    MessageBrokerConfiguration::message_log(key)
  end

  # Administrative message-logging object
  def admin_message_log(key = nil)
    MessageBrokerConfiguration::admin_message_log(key)
  end

  # The error-logging object
  def error_log
    MessageBrokerConfiguration::message_based_error_log
  end

  # The error-logging object
  def log_reader
    MessageBrokerConfiguration::log_reader
  end

  # ReportRequestHandler descendant object, according to 'specs.type'
  def report_handler_for(specs)
    UtilityConfiguration::report_handler_for(specs: specs, config: self)
  end

  #####  Access - classes or modules

  # StatusReport descendant of the appropriate class for the application
  def status_report
    UtilityConfiguration::status_report
  end

  # data serializer
  def serializer
    UtilityConfiguration::serializer
  end

  # data de-serializer
  def de_serializer
    UtilityConfiguration::de_serializer
  end

  # RAM usage of current process in kilobytes
  def mem_usage
    UtilityConfiguration::mem_usage
  end

  post :is_module do |result| result.is_a?(Module) end
  def time_utilities
    TimeUtil
  end

  #####  Boolean queries

  # Is debug-logging enabled?
  def debugging?
    ENV.has_key?(DEBUG_ENV_VAR)
  end

  private #####  Implementation

  EOD_ENV_VAR = 'TIINGO_TOKEN'
  DATA_PATH_ENV_VAR = 'MAS_RUNDIR'
  DEBUG_ENV_VAR = 'STODO_DEBUG'

  def data_retrieval_token
    result = ENV[EOD_ENV_VAR]
    if result.nil? || result.empty? then
      raise "EOD data token environment variable #{EOD_ENV_VAR} not set."
    end
    result
  end

  def mas_data_path
    result = ENV[DATA_PATH_ENV_VAR]
    if result.nil? || result.empty? then
      raise "data path environment variable #{DATA_PATH_ENV_VAR} not set."
    end
    result
  end

  private  ###  Initialization

  # Initialize 'log' to the_log if ! the_log.nil?.  If the_log is nil,
  # initialize 'log' to MessageBrokerConfiguration::message_based_error_log.
  post :log_set do log != nil end
  def initialize(the_log = nil)
    @log = the_log
    if the_log.nil? then
      @log = MessageBrokerConfiguration::message_based_error_log
    end
  end

end
