# Events scheduled at a specific date and time
class ScheduledEvent < STodoTarget

  attr_reader :date_time, :duration, :location

  public

  ###  Access

  def final_reminder
    assert_invariant {invariant}
    if @final_reminder == nil then
      @final_reminder = Reminder.new(date_time)
    end
    @final_reminder
  end

  def to_s_appendix
    "#{DATE_TIME_KEY}: #{date_time}\n" +
    "#{DURATION_KEY}: #{duration}\n" +
    "#{LOCATION_KEY}: #{location}\n"
  end

  ###  Status report

  def spec_type; "appointment" end

  def formal_type
    "Appointment"
  end

  protected

  def set_fields spec
    super spec
    if spec.date_time != nil then
      begin
        @date_time = Time.parse(spec.date_time)
      rescue ArgumentError => e
        # spec.date_time is invalid or empty - not allowed for appointments.
        $log.warn "date_time invalid [#{e}] (#{spec.date_time}) " +
          "in #{formal_type} #{self.handle}"
      end
    else
      $log.warn "date_time is not set in #{formal_type} #{self.handle}"
    end
    @duration = duration_from_spec spec
    @location = spec.location
    # Prevent use of appointments with nil @date_time:
    if @date_time == nil then @valid = false end
  end

  def duration_from_spec spec
    # (For now, just use the spec.duration without filtering or processing.
    # If there's time for refinement later, this could be turned into a
    # Duration object.)
    spec.duration
  end

  ### Hook routine implementations

  def email_subject
    "appointment reminder: #{handle}" + subject_suffix
  end

  def email_body
    result = "title: #{title}\n" + "date_time: " +
      date_time.strftime('%Y-%m-%d %H:%M') + "\n" +
      "duration: #{duration}\ntype: #{formal_type}\n"
    if location != nil then
      result += "location: #{location}\n"
    end
    result += "description: #{content}\n"
  end

  def set_cal_fields calentry
    super calentry
    calentry.time = date_time
    calentry.location = location
    calentry.duration = duration
  end

  ###  class invariant

  def invariant
    @date_time != nil and super
  end

end
