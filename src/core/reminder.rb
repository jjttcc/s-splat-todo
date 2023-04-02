require 'ruby_contracts'
require 'errortools'
require 'postconditionerror'
require 'timetools'

# Objects that represent a promise to remind, on a certain date and time,
# a client/user of an event or occurrence scheduled for that date/time
class Reminder
  include ErrorTools, TimeTools
  include Contracts::DSL

  public

  attr_reader :date_time, :addendum
  alias :time :date_time

  public

  ###  Status report

  # Is this Reminder due to be used for a notification?
  def is_due?
    raise "code defect: abstract method called"
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
    "#{self.class}: #{time_24hour(date_time.getlocal)}"
  end

  ###  Comparison

  def <=> (other)
    date_time <=> other.date_time
  end

  ###  Status setting

  # Mark the Reminder as triggered - i.e., that is_due? was true and the
  # Reminder was used for a notification.
  # postcondition: not is_due?
  post 'not due' do ! self.is_due? end
  def trigger
  end

  ###  Element change

  def addendum=(arg)
    if arg != nil then @addendum = arg end
  end

  ###  Persistence

  def prepare_for_db_write
    # null op - redefine in descendant, if needed
  end

  private

  DEFAULT_TOLERANCE = 300

end
