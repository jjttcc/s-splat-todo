module DateTimeNotificationTools

  MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY =
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  MONDAYS, TUESDAYS, WEDNESDAYS, THURSDAYS, FRIDAYS, SATURDAYS, SUNDAYS =
    'mondays', 'tuesdays', 'wednesdays', 'thursdays', 'fridays', 'saturdays',
    'sundays'
  MON, TUE, WED, THU, FRI, SAT, SUN=
    'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'
  WEEKDAY_EXPR = /\b(mon|tue|wed|thu|fri|sat|sun)/

  MINUTELY, HOURLY, DAILY, WEEKLY, MONTHLY, YEARLY =
    'minutely', 'hourly', 'daily', 'weekly', 'monthly', 'yearly'
  MINUTE, HOUR, DAY, WEEK, MONTH, YEAR =
    'minute', 'hour', 'day', 'week', 'month', 'year'
  MINUTES, HOURS, DAYS, WEEKS, MONTHS, YEARS =
    'minutes', 'hours', 'days', 'weeks', 'months', 'years'
  PERIOD_NOUNS = [MINUTE, HOUR, DAY, WEEK, MONTH, YEAR]
  PLURAL_PERIOD_NOUNS = [MINUTES, HOURS, DAYS, WEEKS, MONTHS, YEARS]
  PERIOD_EXPR = /\b(min|hour|da[iy]|week|mont|year)/

  EVERY = 'every'

  PERIODS = {}
  [MINUTELY, HOURLY, DAILY, WEEKLY, MONTHLY, YEARLY].each do |p|
    PERIODS[p] = true
  end
  i = 0
  PERIOD_NOUN_FOR = {}
  [MINUTELY, HOURLY, DAILY, WEEKLY, MONTHLY, YEARLY].each do |p|
    PERIOD_NOUN_FOR[p] = PERIOD_NOUNS[i]
    i += 1
  end

  WEEKDAYS = {}
  [MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY].each do |d|
    WEEKDAYS[d] = true
  end
  [MON, TUE, WED, THU, FRI, SAT, SUN].each do |d|
    WEEKDAYS[d] = true
  end
  [MONDAYS, TUESDAYS, WEDNESDAYS, THURSDAYS, FRIDAYS,
   SATURDAYS, SUNDAYS].each do |d|
    WEEKDAYS[d] = true
  end

  IGNORE_WORD = {}
  ['starting', 'at', 'every', 'once', 'a'].each do |w|
    IGNORE_WORD[w] = true
  end

  # Element of PERIODS corresponding to 'ptype' (e.g., HOURLY for HOUR)
  def normalized_period_type(ptype)
    result = nil
    if PERIODS[ptype] then
      result = ptype
    else
    periods = PERIODS.keys
      i = 0
      # Search for the index in PERIOD_NOUNS or PLURAL_PERIOD_NOUNS of the
      # element that matches 'ptype'.
      while i < periods.length && PERIOD_NOUNS[i] != ptype do
        i += 1
      end
      if i == periods.length then
        i = 0
        while i < periods.length && PLURAL_PERIOD_NOUNS[i] != ptype do
          i += 1
        end
      end
      if i < periods.length then
        result = periods[i]
      end
    end
    result
  end

  # Standardized form of 'day' (e.g., mondays -> monday)
  def normalized_weekday(day)
    result = nil
    if WEEKDAYS[day] then
      day =~ /([a-z]*[a-r,t-z])s?/
      result = $1
    end
    result
  end

end
