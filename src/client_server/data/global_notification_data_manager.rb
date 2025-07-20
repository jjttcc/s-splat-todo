# frozen_string_literal: true
# vim: ts=2 sw=2 expandtab

require 'redis'
require 'redisbaseddatamanager'
require 'redis_message_broker'
require 'stodo_global_constants'

# Manages global data access for notification purposes, iterating over
# all users and applications.
class GlobalNotificationDataManager
  include STodoGlobalConstants

  # The Redis key for the set storing all user:app combinations.
  ALL_USER_APP_COMBINATIONS_KEY = 'stodo:all_user_app_combinations'

  private

  attr_reader :message_broker

  public

  # Initializes the manager with a RedisMessageBroker instance.
  # @param message_broker [RedisMessageBroker] - an initialized
  # RedisMessageBroker instance.
  def initialize(message_broker)
    @message_broker = message_broker
  end

  # Retrieves all STodoTarget items across all users and applications,
  # grouped by their "app_name:user_id" combination.
  # @return [Hash<String, Hash<String, STodoTarget>>] A hash where keys are
  #   "app_name:user_id" strings and values are hashes of targets for that
  #   combination (keyed by handle).
  def all_targets
    result = {}
    user_app_combinations = message_broker.redis.smembers(
      ALL_USER_APP_COMBINATIONS_KEY)
    puts "DEBUG: GlobalNotificationDataManager#all_targets - user_app_combinations: #{user_app_combinations.inspect}" # Added for debugging

    # Instantiate RedisBasedDataManager once outside the loop
    # Pass the message_broker (which acts as the 'db' for
    # RedisBasedDataManager). The user and appname will be set in the loop.
    data_manager = RedisBasedDataManager.new(message_broker,
                     "__placeholder_user__", "__placeholder_app__",
                     skip_global_set_add: true)
    user_app_combinations.each do |combo|
      user_id, app_name = combo.split(':', 2)
      # Re-contextualize the existing data_manager instance
      data_manager.set_appname_and_user(app_name, user_id)
      begin
        targets_for_combo = data_manager.restored_targets
        result[combo] = targets_for_combo
      rescue StandardError => e
        # Log error but continue processing other combinations.
        # $log.error is not available here directly, so a simple puts
        # for now, or pass a logger in initialize.
        puts "Error retrieving targets for #{combo}: #{e.message}"
      end
    end
    result
  end

end
