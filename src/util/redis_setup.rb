require 'redis'
require 'application_configuration'

# Set up facilities related to redis.
# If service_name is not nil, global variable $log will be set to a Logger
# that is constructed to log to redis, with the main key (the 'key'
# argument to xadd) created by taking 'service_name' and appending the
# process id. In addition, $log_key will be set to this "main key".
# If 'debugging' is true, set global variable $redis to a connected instance
# of a Redis object for use in debugging operations related to redis.
# [to-do: the main issue - redis database connection/abstraction]
def setup_redis(service_name: nil, debugging: false)
  # Set up to use the redis database.
  if ! service_name.nil? then
    mainkey = "#{service_name}#{$$}"
#!!!!to-do: change to use a class to get rid of some of these global vars.
    $redis_log = MessageBrokerConfiguration.admin_message_log(mainkey)
    $log = RedisLoggerDevice.new($redis_log, $redis_log.key).logger
#!!!!to-do: Store $log_key in the database for future use/reading.
    $log_key = mainkey
  end
  if debugging then
    pw = ENV["REDISCLI_AUTH"]
    $redis = ApplicationConfiguration.redis
  end
end
