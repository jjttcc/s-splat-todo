require 'datetimenotificationtools'

class ReminderSpecScanner
  include DateTimeNotificationTools

  public

  ###  Access

  attr_reader :date_time, :period_count, :period_spec

  private

  ### Regular expressions for reminder-spec components
  COMMA = Regexp.new(' *, *| *at *')    # i.e., match a comma or an "at"
  ## date types (re the specification):
  YMD, MDY, WKDAY = 1, 2, 3

  # Scan the contents of 'reminder_spec' and store the appropriate
  # specification from the spec into date_time, period_count, and period_spec.
  def initialize(reminder_spec)
    @date_time = ""
    # (comma-separated parts:)
    c_s_parts = reminder_spec.split(COMMA).map { |w| w.downcase }
    word_groups = []
    c_s_parts.each do |p|
      word_groups << p.split()
    end
    date_type = date_type_for(word_groups)
    # period_count and period_spec, if they exist are always in the last
    # element of word_groups.
    @period_count, @period_spec = period_info(word_groups.last)
    case date_type
    when YMD
      @date_time = date_time_from_ymd(word_groups, self.period_spec != nil)
    when MDY
      @date_time = date_time_from_mdy(word_groups, self.period_spec != nil)
    when WKDAY
      @date_time = date_time_from_wkday(word_groups, self.period_spec != nil)
    end
  end

  def date_type_for(groups)
    weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday",
                "saturday", "sunday"]
    result = nil
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
