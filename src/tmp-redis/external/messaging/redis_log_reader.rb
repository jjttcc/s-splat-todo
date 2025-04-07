require 'log_reader'
require 'redis'
require 'redis_tools'
require 'redis_stream_facilities'

class RedisLogReader
  include Contracts::DSL, RedisStreamFacilities, LogReader, Util, RedisTools

  public

  #####  Constants

  DEFAULT_TRIM_THRESHHOLD = 1000
  STREAM_TYPE = :stream

  #####  Access

  def contents(key:, count: nil)
    redis_log.xrange(key, count: count)
  end

##!!!!!To-do: Consider adding some or all of the functionality available in
##!!!!!'xread' - i.e.: consumer groups; use of saved ids (e.g., in a private
##!!!!!array attribite) to be used in the next 'contents_for' call; ...
##!!!!!(An abstract representation of this functionality will need to go
##!!!!!into 'LogReader'.)  [Delete this comment "soon" if not <whatever>.]

  # If args_hash[:count] != nil, it will be used as a limit for the number
  # of entries retrieved per key; otherwise, there is no limit.
  # If args_hash[:block_msecs] != nil the operation will block, if needed,
  # for the specified number of milliseconds, to wait for input.
  # If args_hash[:new_only] is true, only "new" (i.e., anything that arrives
  # after this method invocation[!!!check!!!]) content will be returned.
  # If args_hash[:start_time].to_i returns a valid number, it will be used
  # as a start-time (i.e., UNIX "seconds-since-the-epoch") such that all
  # log entries before that date/time will be excluded.
  # If args_hash[:end_time].to_i returns a valid number, it will be used
  # as a end-time (i.e., UNIX "seconds-since-the-epoch") such that all
  # log entries later than that date/time will be excluded.
  def contents_for(args_hash)
    key_list, count, new_only, block_msecs, start_time, end_time =
      args_hash[:key_list], args_hash[:count], args_hash[:new_only],
      args_hash[:block_msecs], args_hash[:start_time], args_hash[:end_time]
    if key_list != nil && ! key_list.empty? then
      if key_list.any? { |k| k.to_s == "*" } then
        key_list = all_keys_of_type(STREAM_TYPE, redis_log)
      end
      if is_i?(start_time) || is_i?(end_time) then
        result = contents_for_range(key_list, start_time, end_time, count)
      else
        if new_only then
          ids = key_list.map { LAST_ID }
        else
          ###!!!!!Here is one place we would need to deal with the saved
          #!!!!! "last-read-id(for-key)" if we implement that!!!!!!
          ids = key_list.map { FIRST_ID }
        end
        result = redis_log.xread(key_list, ids, count: count,
                                 block: block_msecs)
      end
    end
    result
  end

  #####  Measurement

  begin

  first_entry_s, last_entry_s = "first-entry", "last-entry"
  INFO_KEYS_MAP = {
    :length              => :count,
    :"#{first_entry_s}"  => :first_entry,
    :"#{last_entry_s}"   => :last_entry,
  }

  def info_for(args_hash)
    result = {}
    key_list = args_hash[:key_list]
    if key_list != nil && ! key_list.empty? then
      if ! key_list.is_a?(Enumerable) then
        key_list = [key_list]   # Attempt to make it enumerable.
      end
      key_list.each do |stream_key|
        info_hash = {}
        info = redis_log.xinfo(:stream, stream_key)
        if info.nil? then
          raise "Unexpected nil result from Redis#xinfo("\
            ":stream, #{stream_key})"
        end
        INFO_KEYS_MAP.keys.each do |k|
          info_hash[INFO_KEYS_MAP[k]] = info[k.to_s]
        end
        result[stream_key] = info_hash.merge(info)
      end
    end
    result
  end

  end

  #####  Removal

  # (Delete all entries associated with 'key_list' - i.e., call:
  # redis_log.del(key_list).)
  def delete_contents(key_list:)
    redis_log.del(key_list)
  end

  # If args_hash[:count] is present and is an integer, it is used to
  # specify a minimum count of entries that is to remain, for args_hash[:key].
  def trim_contents(args_hash)
    keys = args_hash[:key_list]
    if ! keys.is_a?(Enumerable) then
      keys = [keys]
    end
    if keys.any? { |k| k.to_s == "*" } then
      # (Caller specified '*' - i.e., all stream keys.)
      keys = all_keys_of_type(STREAM_TYPE, redis_log)
    end
    threshhold = DEFAULT_TRIM_THRESHHOLD
    if is_i?(args_hash[:count]) then
      threshhold = args_hash[:count]
    end
    keys.each do |k|
      redis_log.xtrim(k, threshhold, approximate: true)
    end
  end

  private

  # Log contents for all keys in 'key_list' whose ids match the specified
  # 'start_time' and 'end_time' (i.e., each id falls within the time-range
  # implied by start_time and end_time), where 'start_time' and 'end_time'
  # are UNIX timestamps - i.e., seconds since the "epoch", implemented by
  # calling 'redis_log.xrange'
  # If 'count' is not nil, it is provided as the 'count' argument for
  # 'xrange'.
  post :result do |result| result != nil && result.is_a?(Hash) end
  def contents_for_range(key_list, start_time, end_time, count)
    result = {}
    fix_time = lambda do |s|
      if s.nil? || ! is_i?(s) then
        '-'
      elsif s.size <= 10 then
        s + '000'
      else
        s
      end
    end
    start_time = fix_time.call(start_time)
    end_time = fix_time.call(end_time)
    key_list.each do |key|
      result[key.to_s] = redis_log.xrange(key, start_time, end_time,
                                          count: count)
    end
    result
  rescue StandardError => e
    raise "contents_for_range - error: #{e}"
  end

  # Initialize with the Redis-port, logging key, and, if supplied, the
  # number of seconds until each logged message is set to expire (which
  # defaults to DEFAULT_EXPIRATION_SECS).
  pre :port_exists do |hash| hash[:redis_port] != nil end
  post :redis_lg  do self.redis_log != nil end
  def initialize(redis_port:)
    init_facilities(redis_port)
  end

end
