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

  # constants used for parsing/keys
  PERIOD_SPEC_KEY, DATE_TIME_KEY, PERIOD_COUNT_KEY =
    'period_spec', 'date_time', 'period_count'

  def initialize(timespecs, expiration_date_time)
    @result = []
    datestring_array = []
    init_time_parsers
#binding.irb
    timespecs.each do |ts|
      @result << reminder_from_spec(ts, expiration_date_time)
    end
  end

  def reminder_from_spec(timespec, expiration_date_time)
#binding.irb
    first_time, period_type, period_count = first_time_period_type_count(
      timespec)
    result = PeriodicReminder.new(first_time, expiration_date_time,
                                  period_type, period_count)
    result
  end

  # 'first_time', 'period_type', and 'period_count' from 'spec' - empty
  # array if 'spec' is not parse-able
  def first_time_period_type_count(spec)
    result = []
    time_spec_for = period_spec_table(spec)
    period_spec = time_spec_for[PERIOD_SPEC_KEY]
    datetime_spec = time_spec_for[DATE_TIME_KEY]
    period_count = time_spec_for[PERIOD_COUNT_KEY].to_i
#binding.irb
    parser = @time_parser_for[period_spec]
    if parser == nil then
      msg = "Could not parse date/time spec: #{spec}"
      raise msg
    end
    result = parser.call(period_spec, datetime_spec, period_count)
    result
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
      # (w is not an ignorable word and is not a period-type word)
      ! IGNORE_WORD[w] && normalized_period_type(w) == nil
    end
    result = workwords.join(' ')
    result
  end

  def period_spec_table(spec)
#!!!!to-do: Consider replacing this function with the use of an instance of a newly
#!!!!designed class.
    result = {}
    datetime = ""
    words = spec.split.map { |w| w.downcase }
    period_found = false
#binding.irb
    words.each do |word|
      if not IGNORE_WORD[word] then
        case word
        when /^\d+$/
          if period_found then
            # The period-count will come before the period-type/weekday, so
            # 'word' is not the period count; assume it's part of the date.
            datetime += " #{word}"
          else
            result[PERIOD_COUNT_KEY] = word
          end
        when WEEKDAY_EXPR, PERIOD_EXPR
# proposed: alteration to date and period setting logic!!!!
          result[PERIOD_SPEC_KEY] = word
          period_found = true
        else
          datetime += " #{word}"
        end
      end
    end
    result[DATE_TIME_KEY] = datetime
    if ! result[PERIOD_COUNT_KEY] then
      result[PERIOD_COUNT_KEY] = '1'
    end
#binding.irb
    result
  end

end
