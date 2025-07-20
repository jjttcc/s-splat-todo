# frozen_string_literal: true
# vim: ts=2 sw=2 expandtab

require 'service'
require 'stodo_services_constants'
require 'configuration'
require 'global_notification_data_manager'

# A long-running service that periodically checks for and sends due reminders.
class NotificationService
  include Service, STodoServicesConstants

  # The interval (in seconds) between checks for due reminders.
  CHECK_INTERVAL_SECONDS = 60

  private

  attr_accessor :global_data_manager, :mailer, :email_notifier, :dirty
  attr_writer   :config

  public

  attr_reader   :config

  alias :configuration :config

  def initialize
    Configuration.service_name = 'notification-service'
    Configuration.debugging = false # Set to true for debugging
    self.config = Configuration.instance
    app_config = config.app_configuration
    self.global_data_manager = GlobalNotificationDataManager.new(
      app_config.application_message_broker)
    # Initialize Mailer and Email notifier
    self.mailer = Mailer.new(config)
    self.email_notifier = Email.new(mailer)
    self.dirty = false # Initialize dirty flag
  end

  private

  # Hook method from Service: Perform any needed preparation before starting
  # the main 'while' loop.
  def prepare_for_main_loop(exe_args)
    puts "NotificationService started. Checking for reminders every " +
         "#{CHECK_INTERVAL_SECONDS} seconds."
  end

  # Hook method from Service: Perform the main processing.
  # Checks all stodo items for due reminders and sends notifications.
  def process(exe_args)
    puts "Checking for due reminders..."
    all_grouped_targets = global_data_manager.all_targets
    all_grouped_targets.each do |combo, targets_for_combo|
      puts "Processing reminders for user/app: #{combo}"
      changed_items_for_combo = []
      # Instantiate RedisBasedDataManager for this specific combo to
      # save changes
      app_name, user_id = combo.split(':', 2)
      data_manager_for_combo = RedisBasedDataManager.new(
        config.app_configuration.application_message_broker, user_id, app_name)
      targets_for_combo.values.each do |target|
        self.dirty = false    # Reset dirty flag for each target
        target.add_notifier(email_notifier)
        target.perform_ongoing_actions(self)
        if self.dirty then
          changed_items_for_combo << target
        end
      end
      if ! changed_items_for_combo.empty? then
        puts "Persisting #{changed_items_for_combo.count} changed items" +
          "for #{combo}."
        changed_items_for_combo.each do |target|
          data_manager_for_combo.store_target(target)
        end
      end
    end
  rescue StandardError => e
    $log.error("Error in process (NotificationService): #{e.message}")
    # Consider more robust error handling, e.g., retry logic, dead-letter queue
  end

  # Hook method from Service: Perform any needed post-processing after
  # 'process' is called.
  def post_process(exe_args)
    sleep CHECK_INTERVAL_SECONDS
  end

end
