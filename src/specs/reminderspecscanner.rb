require 'datetimenotificationtools'
require 'dateparser'

# Instances of this class, when created, scan the given reminder specs and
# the date_time, period_count, and period_spec.
class ReminderSpecScanner
  include DateTimeNotificationTools

  public

  ###  Access

  attr_reader :date_time, :period_count, :period_spec

  private

  ### Regular expressions for reminder-spec components
  COMMA = Regexp.new(' *, *| *at *')    # i.e., match a comma or an "at"

  # Scan the contents of 'reminder_spec' and store the appropriate
  # specification from the spec into date_time, period_count, and period_spec.
  def initialize(reminder_spec)
    @date_time = nil
    @period_count = nil
    @period_spec = nil

    # First, try to extract period info
    c_s_parts = reminder_spec.split(COMMA).map { |w| w.downcase }
    word_groups = []
    c_s_parts.each do |p|
      word_groups << p.split()
    end

    if word_groups.count > 0 then
      @period_count, @period_spec = period_info(word_groups.last)
    end

    # Now, try to parse the date/time component
    date_time_string = reminder_spec
    if @period_spec then
      # If a period is found, remove it from the string before parsing date
      # This is a simplification; a more robust parser would handle this better
      date_time_string =
        reminder_spec.sub(
          /every \d+ (minute|hour|day|week|month|year)s?/i, '').strip
    end

    date_parser = DateParser.new([date_time_string], true)
    parsed_dates = date_parser.result

    if parsed_dates && ! parsed_dates.empty? && parsed_dates[0] then
      @date_time = parsed_dates[0]
    elsif @period_spec then
      # If it's a periodic reminder and no specific date was parsed,
      # default to now.
      @date_time = Time.now.to_s # Convert to string here
    end
  end

  # An array: [period_count, period_spec], extracted from 'period_array'
  # If period_array does contains only incomplete or no period information,
  # result[1] will be nil.
  def period_info(period_array)
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
    result
  end

end
