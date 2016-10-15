require_relative 'mailer'
require_relative 'calendarentry'

# Basic manager of s*todo actions
class STodoManager
  attr_reader :targets, :mailer, :calendar

  public

  # Call `initiate' on each element of @targets.
  def perform_initial_processing
    targets.each do |t|
      t.initiate(self)
    end
  end

  # Call `initiate' on each element of @targets.
  def perform_notifications
    targets.each do |t|
      t.perform_ongoing_actions(self)
    end
  end

  private

  def initialize targets, config
    @targets = targets
    @mailer = Mailer.new config
    @calendar = CalendarEntry.new config
$log.debug "Here's the calendar - what does it look like?: #{@calendar.inspect}"
  end

end
