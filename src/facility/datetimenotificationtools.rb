module DateTimeNotificationTools
  MINUTELY, HOURLY, DAILY, WEEKLY, MONTHLY, YEARLY =
    'minutely', 'hourly', 'daily', 'weekly', 'monthly', 'yearly'

  MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY =
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'

  MON, TUE, WED, THU, FRI, SAT, SUN=
    'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'

  EVERY = 'every'

  PERIODS = {}
  [MINUTELY, HOURLY, DAILY, WEEKLY, MONTHLY, YEARLY].each do |p|
    PERIODS[p] = true
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
