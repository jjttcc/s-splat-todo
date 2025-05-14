require 'ruby_contracts'
require 'errortools'
require 'postconditionerror'
require 'reminder'

# Reminders that only trigger a notification once
class OneTimeReminder < Reminder
  include ErrorTools
  include Contracts::DSL

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

  # Note: This method will cause a state change in 'self' - See
  # documentation in the parent class (Reminder) for more complete info.
  post 'triggered? and not due' do self.triggered? && ! self.is_due? end
  def trigger
    @triggered = true
  end

  private

  # Note: self.date_time is set to 'datetime.clone.utc' - i.e., it
  # is initialized to UTC without changing the object 'datetime'
  # references.
  pre 'datetime set' do |datetime| ! datetime.nil? end
  def initialize(datetime, time_tolerance = DEFAULT_TOLERANCE)
    @date_time = datetime.clone.utc
    @time_tolerance = time_tolerance
    @addendum = ""
  end

end
