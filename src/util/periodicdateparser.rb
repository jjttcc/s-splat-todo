require 'active_support/time'
require 'datetimenotificationtools'
require 'periodicreminder'

# Parser that takes a set of periodic date-time specifications and produces
# a set, in 'result', of resulting "PeriodicReminder"s.
class PeriodicDateParser
  include ErrorTools, DateTimeNotificationTools

  public

  attr_reader :result

  private

  def initialize(timespecs, expiration_date_time)
    @result = []
    datestring_array = []
    init_time_parsers
    timespecs.each do |ts|
      @result << reminder_from_spec(ts, expiration_date_time)
    end
  end

  def reminder_from_spec(timespec, expiration_date_time)
    first_time, period_type, period_count = first_time_period_type_count(
      timespec)
    result = PeriodicReminder.new(first_time, expiration_date_time,
                                  period_type, period_count)
  end

  # 'first_time', 'period_type', and 'period_count' from 'spec' - empty
  # array if 'spec' is not parse-able
  def first_time_period_type_count(spec)
    result = []
    words = spec.split
    case words.first
    when EVERY
      if words.length > 1 then
        result = @time_parser_for[words[1]].call(words)
      end
    when *(PERIODS.keys)
        result = @time_parser_for[words.first].call(words)
    end
    result
  end

  def datetime_from_phrase(words)
    if WEEKDAYS[words[0]] then
      datetime_phrase = weekday_time(words)
    elsif PERIODS[words[0]] then
      datetime_phrase = periodic_time(words[1..-1])
    end
    result = xparser_result(datetime_phrase)
    result
  end

  def xparser_result(datetime_string)
    if datetime_string == nil then
      raise "xparser_result called with nil argument"
    end
    xparser = ExternalDateParser.new([datetime_string])
    result = xparser.result[0]
    if xparser.parse_failed then
      error = (xparser.error_msg != nil) ? xparser.error_msg :
        "parse failed for date string: #{datetime_string}"
      raise error
    end
    result
  end

  def init_time_parsers
    @time_parser_for = {}
    weekday_parser = lambda do |words|
      result = []
      period_type = WEEKLY; period_count = 1
      first_time = datetime_from_phrase(words[1 .. -1])
      if first_time && period_type && period_count then
        result = [first_time, period_type, period_count]
      end
      result
    end
    period_parser = lambda do |words|
      result = []
      period_type = words.first; period_count = 1
      first_time = datetime_from_phrase(words)
      if first_time && period_type && period_count then
        result = [first_time, period_type, period_count]
      end
      result
    end
    WEEKDAYS.keys.each do |day|
      @time_parser_for[day] = weekday_parser
    end
    PERIODS.keys.each do |p|
      @time_parser_for[p] = period_parser
    end
  end

  def weekday_time(words)
    timeindex = 1
    case words[1]
    when "at", "@"
      timeindex = 2
    end
    time = words[timeindex .. -1].join(' ')
    result = "next #{words[0]} at #{time}"
    result
  end

  def periodic_time(words)
    workwords = words.select do |w|
      ! IGNORE_WORD[w]
    end
    result = workwords.join(' ')
    result
  end

end