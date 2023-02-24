require 'ruby_contracts'
require 'active_support/time'
require 'errortools'
require 'datetimenotificationtools'
require 'reminder'

# Reminders that trigger on a periodic, rather than a one-time, basis - for
# example: Remind the client every Thursday at 2 pm.
class PeriodicReminder < Reminder
  include ErrorTools, DateTimeNotificationTools
  include Contracts::DSL

  # date/time after which no more reminder/notifications will be triggered
  attr_reader :ending_date_time
  # type/duration of self's period - i.e., daily, weekly, monthly, or yearly
  attr_reader :period_type
  # number of periods between notifications (e.g., period_count == 3 and
  # period_type == weekly means once notify every 3 weeks)
  attr_reader :period_count

  alias :next_date_time :date_time

  public

  ###  Status report

  def is_due?(now = nil)
    if now == nil then
      now = Time.now
    end
    result = now >= next_date_time && now <= ending_date_time
    $log.debug "is_due? called with now: #{now}, endtime: #{ending_date_time}"
    $log.debug "is_due? next_date_time: #{next_date_time}"
    result
  end

  def to_str
    period_info = ", every #{period_count} #{PERIOD_NOUN_FOR[period_type]}"
    if period_count > 1 then
      period_info += "s"
    end
    super + period_info
  end

  ###  Status setting

  def trigger
    if @advancer_for == nil then
      init_advancers
    end
    # Advance '@date_time' based on period_type and period_count.
    now = Time.now
    $log.debug "[PeriodicReminder.trigger] (before) now, date_time: " +
      now.to_s + ", #{@date_time}"
    advancer = @advancer_for[period_type]
    # Call advancer in a while loop to handle the case of being behind -
    # E.g.: (hourly) it is 16:50 and the reminder/notification for 14:00 was
    # just triggered.  To ensure '! is_due?' and to avoid unnecessary
    # rapid-fire notifications, discard notifications for 15:00 and 16:00.
    limit = 10_000_000  # To prevent infinite accidents
    i = 1
    while is_due?(now) && i <= limit
      advancer.call(period_count)
      i += 1
    end
    $log.debug "[PeriodicReminder.trigger] (after) now, date_time: " +
      now.to_s + ", #{@date_time}"
    $log.debug "[PeriodicReminder.trigger] is_due? #{is_due?}"
    super # (Check postcondition.)
  end

  ###  Persistence

  def prepare_for_db_write
    @advancer_for = nil
  end

  private

  pre 'valid first and end date/times' do |first_dt, ending_dt|
        first_dt.is_a?(Time) && ending_dt.is_a?(Time)
  end
  pre 'normalized period_type' do |fdt, edt, period_type|
    normalized_period_type(period_type) != nil
  end
  def initialize(first_date_time, ending_date_time, period_type,
                 period_count, time_tolerance = DEFAULT_TOLERANCE)
    @date_time = first_date_time
    @ending_date_time = ending_date_time
    @period_type = normalized_period_type(period_type)
    @period_count = period_count
    @time_tolerance = time_tolerance
    @addendum = ""
    init_advancers
  end

  def init_advancers
    @advancer_for = {}
    @advancer_for[MINUTELY] = lambda do |pers|
      @date_time = @date_time.advance(minutes: pers)
    end
    @advancer_for[HOURLY]   = lambda do |pers|
      @date_time = @date_time.advance(hours: pers)
    end
    @advancer_for[DAILY]    = lambda do |pers|
      @date_time = @date_time.advance(days: pers)
    end
    @advancer_for[WEEKLY]   = lambda do |pers|
      @date_time = @date_time.advance(weeks: pers)
    end
    @advancer_for[MONTHLY]  = lambda do |pers|
      @date_time = @date_time.advance(months: pers)
    end
    @advancer_for[YEARLY]   = lambda do |pers|
      @date_time = @date_time.advance(years: pers)
    end
  end

end
