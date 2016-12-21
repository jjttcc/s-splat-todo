require 'errortools'
require 'postconditionerror'
require 'reminder'

# Reminders that only trigger a notification once
class OneTimeReminder < Reminder
  include ErrorTools

  public

  ###  Status report

  # Has this reminder been triggered - i.e., is the current time later than
  # 'date_time' and, as a result, has the target, the person to be reminded,
  # been notified that the reminder has come due, chronologically?
  def triggered?
    @triggered
  end

  # not triggered? and `date_time' equals or is earlier than the current
  # date/time?
  # postcondition: result implies not triggered?
  def is_due?
    result = ! triggered?
    if result then
      current_unix_secs = Time.now.strftime('%s').to_i
      reminder_unix_secs = date_time.strftime('%s').to_i
      result = (current_unix_secs >= reminder_unix_secs)
    end
    if not implies(result, ! triggered?) then
      raise PostconditionError, 'result implies not triggered?'
    end
    result
  end

  ###  Status setting

  # postcondition: triggered? and not is_due?
  def trigger
    @triggered = true
    assert_postcondition('triggered? and not is_due?') {
      triggered? and not is_due?}
  end

  private

  # precondition: datetime != nil
  def initialize(datetime, time_tolerance = DEFAULT_TOLERANCE)
    assert_precondition {datetime != nil}
    @date_time = datetime
    @time_tolerance = time_tolerance
    @addendum = ""
  end

end
