# Events scheduled at a specific date and time
class ScheduledEvent < STodoTarget
  public

  attr_reader :date_time, :duration, :location

  public

  ###  Access

  def time
    date_time
  end

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

  ###  Element change

  def modify_fields spec
    super spec
    if spec.date_time != nil then
      set_date_time spec
    end
    @duration = duration_from_spec spec if spec.duration
    @location = spec.location if spec.location
  end

  protected

  def set_fields spec
    super spec
    if spec.date_time != nil then
      set_date_time spec
    else
      $log.warn "date_time is not set in #{formal_type} #{self.handle}"
    end
    @duration = duration_from_spec spec
    @location = spec.location
    # Prevent use of appointments with nil @date_time:
    if @date_time == nil then @valid = false end
  end

  def set_date_time spec
    begin
      @date_time = Time.parse(spec.date_time)
    rescue ArgumentError => e
      # spec.date_time is invalid or empty - not allowed for appointments.
      $log.warn "date_time invalid [#{e}] (#{spec.date_time}) " +
        "in #{formal_type} #{self.handle}"
    end
  end

  def duration_from_spec spec
    # (For now, just use the spec.duration without filtering or processing.
    # If there's time for refinement later, this could be turned into a
    # Duration object.)
    spec.duration
  end

  ### Hook routine implementations

  def message_subject_label
    "appointment: "
  end

  def current_message_subject
    "#{title} [#{handle}]"
  end

  def current_message
    result = "title: #{title}\n" + "date_time: " +
      date_time.strftime('%Y-%m-%d %H:%M') + "\n" +
      "duration: #{duration}\ntype: #{formal_type}\n"
    if location != nil then
      result += "location: #{location}\n"
    end
    if priority then
      result += "priority: #{priority}\n"
    end
    result += "description: #{content}\n"
  end

  def set_cal_fields calentry
    super calentry
    calentry.time = date_time
    calentry.location = location
    calentry.duration = duration
  end

  ###  Persistence

  def marshal_dump
    result = super
    result.merge!({
      'date_time' => date_time,
      'duration' => duration,
      'location' => location,
      'final_reminder' => final_reminder
    })
    result
  end

  def marshal_load(data)
    super(data)
    @date_time = data['date_time']
    @duration = data['duration']
    @location = data['location']
    @final_reminder = data['final_reminder']
  end

  ###  class invariant

  def invariant
    @date_time != nil and super
  end

end
