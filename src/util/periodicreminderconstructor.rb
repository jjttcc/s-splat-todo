require 'active_support/time'
require 'datetimenotificationtools'
require 'periodicreminder'


# Constructor of a "PeriodicReminder" based on a periodic date-time
# specification
class PeriodicReminderConstructor
  include ErrorTools, DateTimeNotificationTools

  public

  attr_reader :result

  private

  # constants used for parsing/keys
  PERIOD_SPEC_KEY, DATE_TIME_KEY, PERIOD_COUNT_KEY =
    'period_spec', 'date_time', 'period_count'

  def initialize(reminder_spec, expiration_date_time)
    init_time_parsers
    parser = @time_parser_for[reminder_spec.period_spec]
    if parser == nil then
      msg = "Could not parse date/time spec: #{spec}"
      raise msg
    end
    datetime, period_type, period_count = parser.call(
      reminder_spec.period_spec, reminder_spec.date_time,
      reminder_spec.period_count)
    @result = PeriodicReminder.new(datetime, expiration_date_time,
                                  period_type, period_count.to_i)
  end

  def xparser_result(datetime_string)
    if datetime_string == nil then
      raise "xparser_result called with nil argument"
    end
    xparser = ExternalDateParser.new([datetime_string])
    result = xparser.result[0]
    if xparser.parse_failed then
      if xparser.error_msg != nil && ! xparser.error_msg.empty? then
        error = xparser.error_msg
      else
        error = "parse failed for date string: '#{datetime_string}'"
      end
      raise error
    end
    result
  end

  # Initialize '@time_parser_for', which returns an array:
  # [<datetime>, <period_type>, <period_count>].
  def init_time_parsers
    @time_parser_for = {}
    weekday_parser = lambda do |dayofweek, time, pcount = nil|
      result = []
      dayofweek = normalized_weekday(dayofweek)
      period_type = WEEKLY
      period_count = 1
      first_time = "#{dayofweek} #{time}"
      datetime = xparser_result(first_time)
      result = [datetime, period_type, period_count]
      result
    end
    period_parser = lambda do |period_type, date_phrase, period_count|
      result = []
      datetime = xparser_result(date_phrase)
      result = [datetime, period_type, period_count]
      result
    end
    WEEKDAYS.keys.each do |day|
      @time_parser_for[day] = weekday_parser
    end
    (PERIODS.keys + PERIOD_NOUNS + PLURAL_PERIOD_NOUNS).each do |p|
      @time_parser_for[p] = period_parser
    end
  end

end
