require 'active_support/time'
require 'ruby_contracts'

# Time- and date-related utility functions
module TimeUtil
  include Contracts::DSL

  # Current date and time
  post :exists do |result| result != nil end
  def self.current_date_time
    DateTime.current
  end

  # Current date and time with nanoseconds, as a string -
  # In the format:
  #   <yyyymmdd><separator><hhmmss><separator><fractional-seconds>
  def self.current_nano_date_time(separator = '.')
    Time.now.strftime("%Y%m%d#{separator}%H%M%S#{separator}%9N")
  end

  # Current date and time with microseconds, as a string -
  # In the format:
  #   <yyyymmdd><separator><hhmmss><separator><fractional-seconds>
  def self.current_micro_date_time(separator = '.')
    Time.now.strftime("%Y%m%d#{separator}%H%M%S#{separator}%6N")
  end

  pre  :tz_good do |tz| ! tz.nil? end
  pre  :dt_good do |tz, datetime| ! datetime.nil? end
  post :exists do |result| result != nil end
  def self.local_time(timezone, datetime = current_date_time)
    result = datetime.in_time_zone(timezone)
    result
  rescue NoMethodError => err
    # (Cover the case in which 'datetime' does not have an 'in_time_zone'
    # method.)
    return ActiveSupport::TimeWithZone.new(datetime,
                                        datetime.zone).in_time_zone(timezone)
  end

  # A new date-time created by, essentially, cloning 'datetime' and then
  # setting its hour and minute components to 'hour' and 'minute',
  # respectively and its date (ymd) components to those of 'datetime'.
  pre  :args_good do |dt, h, m| ! (dt.nil? || h.nil? || m.nil?) end
  post :result_exists do |result| result != nil end
  post :result_good do |result|
    result.hour == hour && result.minute == minute end
  def self.new_time_from_h_m(datetime, hour, minute)
    result = datetime.change(hour: hour, min: minute)
    result
  rescue NoMethodError => err
    # (Cover the case in which 'datetime' does not have a 'change' method.)
    dt = DateTime.new(datetime.year, datetime.month, datetime.day,
                         hour, minute)
    dt.change(hour: hour, min: minute)
  end

end
