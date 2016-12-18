require 'active_support/time'
require 'errortools'
require 'datetimenotificationtools'

# Reminders that trigger on a periodic, rather than a one-time, basis - for
# example: Remind the client every Thursday at 2 pm.
class PeriodicReminder
  include ErrorTools, DateTimeNotificationTools

# = ""  #!!!!!!!!!!Needed???!!!!!!!
def addendum
  ""
end
  public

  # date/time of the next upcoming reminder/notification
  attr_reader :next_date_time
  # date/time after which no more reminder/notifications will be triggered
  attr_reader :ending_date_time
  # type/duration of self's period - i.e., daily, weekly, monthly, or yearly
  attr_reader :period_type
  # number of periods between notifications (e.g., period_count == 3 and
  # period_type == weekly means once notify every 3 weeks)
  attr_reader :period_count

  alias :time :next_date_time
  alias :date_time :next_date_time

  public

  ###  Status report

#!!!!!!!!!!To-be-adapted!!!!!!!!!!!!!!!!!!!!!!

#!!!!(This feature, hopefully, can be removed.!!!!!!!!!)
  # Has this reminder been triggered - i.e., is the current time later than
  # 'date_time' and, as a result, has the target, the person to be reminded,
  # been notified that the reminder has come due, chronologically?
  def triggered?
    @triggered
  end

  # Has this reminder expired?
  def expired?
    now_plus_tolerance = Time.now.advance(seconds: time_tolerance)
    result = now_plus_tolerance > ending_date_time
    result
  end

  # (!!!!New description needed!!!!)
  def is_due?
    now = Time.now
    result = now >= next_date_time && now <= ending_date_time
    result
  end

  # Is the current date/time more than 'time_tolerance' seconds later than
  # `date_time'?
  def is_late?
    current_unix_secs = Time.now.strftime('%s').to_i
    reminder_unix_secs = date_time.strftime('%s').to_i
    current_unix_secs - reminder_unix_secs > time_tolerance
  end

#!!!!!(Move to a [new] parent class:)!!!!!!!
  def time_tolerance
    @time_tolerance
  end

  def to_str
    "#{self.class}: (#{date_time})"
  end

  ###  Comparison

#!!!!!(Move to a [new] parent class:)!!!!!!!
  def <=> (other)
    date_time <=> other.date_time
  end

  ###  Status setting

  # !!!!Need new description!!!!!
  def trigger
    # Advance 'next_date_time' based on period_type and period_count.
    case period_type
    when MINUTELY
      @next_date_time = next_date_time.advance(minutes: period_count)
    when HOURLY
      @next_date_time = next_date_time.advance(hours: period_count)
    when DAILY
      @next_date_time = next_date_time.advance(days: period_count)
    when WEEKLY
      @next_date_time = next_date_time.advance(weeks: period_count)
    when MONTHLY
      @next_date_time = next_date_time.advance(months: period_count)
    when YEARLY
      @next_date_time = next_date_time.advance(years: period_count)
    end
  end

  ###  Element change

  private

  DEFAULT_TOLERANCE = 300

  def initialize(first_date_time, ending_date_time, period_type,
                 period_count, time_tolerance = DEFAULT_TOLERANCE)
    assert_precondition(
      'first_date_time.is_a?(Time) && ending_date_time.is_a?(Time)') {
        first_date_time.is_a?(Time) && ending_date_time.is_a?(Time)
    }
    assert_precondition('PERIODS[period_type]') {
      PERIODS[period_type]
    }
    @next_date_time = first_date_time
    @ending_date_time = ending_date_time
    @period_type = period_type
    @period_count = period_count
#!!!!@triggered = false
    @time_tolerance = time_tolerance
  end

end
