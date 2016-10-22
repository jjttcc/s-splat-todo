#require 'date'

class Reminder
  public

  attr_reader :date_time

  public

  # Has this reminder been triggered - i.e., is the current time later than
  # 'date_time' and, as a result, has the target, the person to be reminded,
  # been notified that the reminder has come due, chronologically?
  def triggered?
  end

  # Has this reminder expired?
  def expired?
    current_unix_secs = DateTime.now.strftime('%s').to_i
    reminder_unix_secs = date_time.strftime('%s').to_i
    current_unix_secs - reminder_unix_secs > time_tolerance
  end

  # If "not triggered?" and the current date/time is later than
  # 'date_time', carry out any notifications assigned to this reminder.
  # precondition: not triggered?
  def execute
  end

  # The maximum difference, in seconds, between 'date_time' and the current
  # date/time that is "allowed" such that this reminder must have been
  # triggered or is to be considered "delinquent"
  def time_tolerance
    @time_tolerance
  end

  private

  DEFAULT_TOLERANCE = 300

  def initialize(datetime, time_tolerance = DEFAULT_TOLERANCE)
    begin
      @date_time = DateTime.parse(datetime)
    rescue ArgumentError => e
      raise "Bad datetime: #{datetime} [#{e.inspect}]"
    end
    @triggered = false
    @time_tolerance = time_tolerance
  end

end
