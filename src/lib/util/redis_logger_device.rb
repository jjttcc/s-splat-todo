# A "log device" (logdev) needed by Logger.new [first argument], which
# Logger uses to actually log - write - the intended message. This device uses
# a RedisLog instance in its "write" method to store the log message.
class RedisLoggerDevice
  include Contracts::DSL

  public  ###  Basic operations

  attr_reader :logger, :redis_log, :stream_key

  def write(message)
#    binding.irb
# example 'message':
#W, [2025-04-09T17:03:56.421626 #3333547]  WARN -- : a logger device
    message =~ /([a-zA-Z], *[^:]*:..:[^:]*): (.*)/
    header = $1
    msg = $2
    # save 'msg' to the redis log.
    redis_log.send_message(log_key: stream_key, tag: header, msg: msg)
  end

  def close
    # no-op
  end

  protected

  attr_writer :logger, :redis_log, :stream_key

  pre  :redis_log do |redis_log|
    ! redis_log.nil? && redis_log.is_a?(RedisLog)
  end
  pre  :stream_key do |stream_key| ! stream_key.nil?  end
  post :redis_log_set do |res, redis_log|
    self.redis_log == redis_log
  end
  post :stream_key_set do |res, redis_log, stream_key|
    self.stream_key == stream_key
  end
  post :logger do |res, redis_log, skey, loggr|
    implies(! loggr.nil?, self.logger == loggr)
  end
  def initialize(redis_log, stream_key, loggr = nil)
    self.redis_log = redis_log
    self.stream_key = stream_key
    if ! loggr.nil? then
      self.logger = loggr
    else
      self.logger = Logger.new(self)
    end
  end

end
