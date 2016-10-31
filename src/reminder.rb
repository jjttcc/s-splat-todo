require_relative 'errortools'
require_relative 'postconditionerror'

class Reminder
  include ErrorTools

  public

  attr_reader :date_time, :addendum

  public

  ###  Status report

  # Has this reminder been triggered - i.e., is the current time later than
  # 'date_time' and, as a result, has the target, the person to be reminded,
  # been notified that the reminder has come due, chronologically?
  def triggered?
    @triggered
  end

  # Has this reminder expired?
  def expired?
    current_unix_secs = Time.now.strftime('%s').to_i
    reminder_unix_secs = date_time.strftime('%s').to_i
    current_unix_secs - reminder_unix_secs > time_tolerance
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

  # Is the current date/time more than 'time_tolerance' seconds later than
  # `date_time'?
  def is_late?
    current_unix_secs = Time.now.strftime('%s').to_i
    reminder_unix_secs = date_time.strftime('%s').to_i
    current_unix_secs - reminder_unix_secs > time_tolerance
  end

  # The maximum difference, in seconds, between 'date_time' and the current
  # date/time that is "allowed" such that this reminder must have been
  # triggered or is to be considered "delinquent"
  def time_tolerance
    @time_tolerance
  end

  def to_str
    "#{self.class}: (#{date_time})"
  end

  ###  Comparison

  def <=> (other)
    date_time <=> other.date_time
  end

  ###  Status setting

  # Change status to triggered
  # precondition: not triggered?
  # postcondition: triggered? and not is_due?
  def trigger
    assert_precondition('not triggered?') {not triggered?}
    @triggered = true
    assert_postcondition('triggered? and not is_due?') {
      triggered? and not is_due?}
  end

  ###  Element change

  def addendum=(arg)
    if arg != nil then @addendum = arg end
  end

  private

  DEFAULT_TOLERANCE = 300

  # precondition: datetime != nil
  def initialize(datetime, time_tolerance = DEFAULT_TOLERANCE)
    assert_precondition {datetime != nil}
    if datetime.class.to_s == 'String' then
      begin
        @date_time = Time.parse(datetime)
      rescue ArgumentError => e
        raise "Bad datetime: #{datetime} [#{e.inspect}]"
      end
    else
      @date_time = datetime
    end
    @triggered = false
    @time_tolerance = time_tolerance
    @addendum = ""
  end

end
