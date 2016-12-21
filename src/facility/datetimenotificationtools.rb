module DateTimeNotificationTools
  MINUTELY, HOURLY, DAILY, WEEKLY, MONTHLY, YEARLY =
    'minutely', 'hourly', 'daily', 'weekly', 'monthly', 'yearly'

  MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY =
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'

  MON, TUE, WED, THU, FRI, SAT, SUN=
    'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'

  MINUTE, HOUR, DAY, WEEK, MONTH, YEAR =
    'minute', 'hour', 'day', 'week', 'month', 'year'
  PERIOD_NOUNS = [MINUTE, HOUR, DAY, WEEK, MONTH, YEAR]

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

  IGNORE_WORD = {}
  ['starting', 'at'].each do |w|
    IGNORE_WORD[w] = true
  end
end
