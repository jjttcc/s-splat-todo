require 'active_support/time'
require 'datetimenotificationtools'
require 'periodicreminder'
#require 'reminderspecscanner'

######################################
module ReminderSpecScanner
  include DateTimeNotificationTools

  public

  ###  Access

  attr_reader :date_time, :period_count, :period_spec

  private

  COMMA = Regexp.new(' *, *| *at *')    # i.e., match a comma or an "at"
  ## date types (re the specification):
  YMD, MDY, WKDAY = 1, 2, 3

  # Scan the contents of 'reminder_spec' and store the appropriate
  # specifiation from the spec into date_time, period_count, and period_spec.
  def set_rem_specs(reminder_spec)
###binding.irb
    @date_time = ""
    # (comma-separated parts:)
    c_s_parts = reminder_spec.split(COMMA).map { |w| w.downcase }
    word_groups = []
    c_s_parts.each do |p|
      word_groups << p.split()
    end
    $log.warn "[set_rem_specs] word_groups: #{word_groups}"
    date_type = date_type_for(word_groups)
    # period_count and period_spec, if they exist are always in the last element
    # of word_groups.
###binding.irb
$log.warn "[set_rem_specs] calling period_info with #{word_groups.last}"
    @period_count, @period_spec = period_info(word_groups.last)
$log.warn "[set_rem_specs] @period_count, @period_spec: #{@period_count}, #{@period_spec}"
    case date_type
    when YMD
      $log.warn "[set_rem_specs] date_type is YMD"
      @date_time = date_time_from_ymd(word_groups, self.period_spec != nil)
    when MDY
      $log.warn "[set_rem_specs] date_type is MDY"
      @date_time = date_time_from_mdy(word_groups, self.period_spec != nil)
    when WKDAY
      $log.warn "[set_rem_specs] date_type is WKDAY"
      @date_time = date_time_from_wkday(word_groups, self.period_spec != nil)
    end
$log.warn "[set_rem_specs] @date_time: #{@date_time}"
=begin
# use this:?
    if ! self.period_count then
      @period_count = '1'
    end
=end
  end

  def date_type_for(groups)
    weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday",
                "saturday", "sunday"]
    result = nil
###binding.irb
    if groups[1][0] =~ /^\d{4}$/ && groups[0].count == 2 then
      result = MDY
    elsif groups[0][0] =~ /^\d{4}-\d\d?-\d\d?$/ then
      result = YMD
    else
      first_part = groups[0]
      target = first_part[0]
      if target =~ /next/i then
        target = first_part[1]
      end
      if weekdays.include?(target.downcase) then
        result = WKDAY
      end
    end
    result
  end

  def date_time_from_ymd(word_groups, ignore_last_group)
###binding.irb
    result = word_groups[0][0]
    time_index = nil
    if ignore_last_group then
      if word_groups.count >= 3 then
        time_index = word_groups.count - 2
      end
    else
      if word_groups.count >= 2 then
        time_index = 1
      end
    end
    if time_index != nil then
      result = "#{result} #{word_groups[time_index][0]}"
    end
    result
  end

  def date_time_from_mdy(word_groups, ignore_last_group)
###binding.irb
    result = "#{word_groups[0][0]} #{word_groups[0][1]}"  # month, day
    result = "#{result}, #{word_groups[1][0]}"            # year
    time_index = nil
    if ignore_last_group then
      if word_groups.count >= 4 then
        time_index = word_groups.count - 2
      end
    else
      if word_groups.count >= 3 then
        time_index = 2
      end
    end
    if time_index != nil then
      result = "#{result} #{word_groups[time_index][0]}"
    end
  end

  def date_time_from_wkday(word_groups, ignore_last_group)
binding.irb
    result = word_groups[0][0]
    if word_groups[0].count > 1 then
      # Assume result == "next" before this assignment.
      result = "#{result} #{word_groups[0][1]}"
    end
    time_index = nil
    if ignore_last_group then
      if word_groups.count >= 3 then
        time_index = word_groups.count - 2
      end
    else
      if word_groups.count >= 2 then
        time_index = 1
      end
    end
    if time_index != nil then
      result = "#{result} #{word_groups[time_index][0]}"
    end
    result
  end

  # An array: [period_count, period_spec], extracted from 'period_array'
  # If period_array does contains only incomplete or no period information,
  # result[1] will be nil.
  def period_info(period_array)
###binding.irb
    result = [nil, nil]
    period_array.each do |word|
      if not IGNORE_WORD[word] then
        case word
        when /^\d+$/
            result[0] = word
        when WEEKDAY_EXPR, PERIOD_EXPR
          result[1] = word
        end
      end
    end
    if result.count > 1 && ! result[0] then
      # (result.count == 0 implies there is no period_spec)
      result[0] = '1'
    end
$log.warn "[period_info] result: #{result}"
    result
  end

  # Scan the contents of 'reminder_spec' and store the appropriate specifiation from the
  # spec into date_time, period_count, and period_spec.
  def old__set_rem_specs(reminder_spec)
    @date_time = ""
    words = reminder_spec.split.map { |w| w.downcase }
    period_found = false
###binding.irb
    words.each do |word|
      if not IGNORE_WORD[word] then
        case word
        when /^\d+$/
          if period_found then
            # The period-count will come before the period-type/weekday, so
            # 'word' is not the period count; assume it's part of the date.
            @date_time += " #{word}"
          else
            @period_count = word
          end
        when WEEKDAY_EXPR, PERIOD_EXPR
# proposed: alteration to date and period setting logic!!!!
          @period_spec = word
          period_found = true
        else
          @date_time += " #{word}"
        end
      end
    end
###binding.irb
    if ! self.period_count then
      @period_count = '1'
    end
  end

end
######################################

# Parser that takes a set of periodic date-time specifications and produces
# a set, in 'result', of resulting "PeriodicReminder"s.
class PeriodicDateParser
  include ErrorTools, DateTimeNotificationTools
  include ReminderSpecScanner #!!!!!!

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
    result = {}
#binding.irb
=begin
    timescanner = ReminderSpecScanner.new(spec)
    result[DATE_TIME_KEY] = timescanner.date_time
    result[PERIOD_COUNT_KEY] = timescanner.period_count
    result[PERIOD_SPEC_KEY] = timescanner.period_spec
=end
    set_rem_specs(spec)
    result[DATE_TIME_KEY] = self.date_time
    result[PERIOD_COUNT_KEY] = self.period_count
    result[PERIOD_SPEC_KEY] = self.period_spec
    result
  end

  def old___period_spec_table(spec)
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
