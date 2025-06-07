# Symbols, method names, etc. used for TAT services
#!!!!Remove this class/file if it is not used!!!
module ServiceTokens

  public

  # Symbol-tags for services
  MESSAGE_BROKER                = :message_broker
  CREATE_NOTIFICATIONS          = :create_notifications
  FINISH_NOTIFICATIONS          = :finish_notifications
  PERFORM_NOTIFICATIONS         = :perform_notifications
  PERFORM_ANALYSIS              = :perform_analysis
  START_ANALYSIS_SERVICE        = :start_analysis_service
  START_POST_PROCESSING_SERVICE = :start_post_processing_service
  EOD_EXCHANGE_MONITORING       = :eod_exchange_monitoring
  MANAGE_TRADABLE_TRACKING      = :manage_tradable_tracking
  EOD_DATA_RETRIEVAL            = :eod_data_retrieval
  EOD_EVENT_TRIGGERING          = :eod_event_triggering
  TRIGGER_PROCESSING            = :trigger_processing
  NOTIFICATION_PROCESSING       = :notification_processing
  STATUS_REPORTING              = :status_reporting

  MAIN_SERVER                   = :main_server

  SERVICE_EXISTS = Hash[
    [MESSAGE_BROKER, CREATE_NOTIFICATIONS, FINISH_NOTIFICATIONS,
     PERFORM_NOTIFICATIONS, PERFORM_ANALYSIS, START_ANALYSIS_SERVICE,
     START_POST_PROCESSING_SERVICE, EOD_DATA_RETRIEVAL,
     EOD_EXCHANGE_MONITORING, MANAGE_TRADABLE_TRACKING,
     EOD_EVENT_TRIGGERING, STATUS_REPORTING MAIN_SERVER].map do |s|
      [s, true]
    end
  ]

  MANAGED_SERVICES = [
    EOD_DATA_RETRIEVAL,
    EOD_EXCHANGE_MONITORING,
    MANAGE_TRADABLE_TRACKING,
    EOD_EVENT_TRIGGERING,
    STATUS_REPORTING,
    MAIN_SERVER,
  ]

#!!!Any use for stodo?:
  # Mapping of the task symbol-tags to status keys
  STATUS_KEY_FOR = {
    CREATE_NOTIFICATIONS          => "#{CREATE_NOTIFICATIONS}_status",
    FINISH_NOTIFICATIONS          => "#{FINISH_NOTIFICATIONS}_status",
    PERFORM_NOTIFICATIONS         => "#{PERFORM_NOTIFICATIONS}_status",
    PERFORM_ANALYSIS              => "#{PERFORM_ANALYSIS}_status",
    START_ANALYSIS_SERVICE        => "#{START_ANALYSIS_SERVICE}_status",
    START_POST_PROCESSING_SERVICE => "#{START_POST_PROCESSING_SERVICE}_status",
    EOD_DATA_RETRIEVAL            => "#{EOD_DATA_RETRIEVAL}_status",
    EOD_EXCHANGE_MONITORING       => "#{EOD_EXCHANGE_MONITORING}_status",
    MANAGE_TRADABLE_TRACKING      => "#{MANAGE_TRADABLE_TRACKING}_status",
    EOD_EVENT_TRIGGERING          => "#{EOD_EVENT_TRIGGERING}_status",
    TRIGGER_PROCESSING            => "#{TRIGGER_PROCESSING}_status",
    NOTIFICATION_PROCESSING       => "#{NOTIFICATION_PROCESSING}_status",
    STATUS_REPORTING              => "#{STATUS_REPORTING}_status",
  }

  # Mapping of the task symbol-tags to control keys
  CONTROL_KEY_FOR = {
    CREATE_NOTIFICATIONS          => "#{CREATE_NOTIFICATIONS}_control",
    FINISH_NOTIFICATIONS          => "#{FINISH_NOTIFICATIONS}_control",
    PERFORM_NOTIFICATIONS         => "#{PERFORM_NOTIFICATIONS}_control",
    PERFORM_ANALYSIS              => "#{PERFORM_ANALYSIS}_control",
    START_ANALYSIS_SERVICE        => "#{START_ANALYSIS_SERVICE}_control",
    START_POST_PROCESSING_SERVICE => "#{START_POST_PROCESSING_SERVICE}_control",
    EOD_DATA_RETRIEVAL            => "#{EOD_DATA_RETRIEVAL}_control",
    EOD_EXCHANGE_MONITORING       => "#{EOD_EXCHANGE_MONITORING}_control",
    MANAGE_TRADABLE_TRACKING      => "#{MANAGE_TRADABLE_TRACKING}_control",
    EOD_EVENT_TRIGGERING          => "#{EOD_EVENT_TRIGGERING}_control",
    TRIGGER_PROCESSING            => "#{TRIGGER_PROCESSING}_control",
    NOTIFICATION_PROCESSING       => "#{NOTIFICATION_PROCESSING}_control",
    STATUS_REPORTING              => "#{STATUS_REPORTING}_control",
  }

end
