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
    "#{DATE_TIME_KEY}: #{time_24hour(date_time)}\n" +
    "#{DURATION_KEY}: #{duration}\n" +
    "#{LOCATION_KEY}: #{location}\n"
  end

  ###  Status report

  def spec_type; APPOINTMENT end

  def formal_type
    "Appointment"
  end

  ###  Element change

  def modify_fields spec
    super spec
    if spec.date_time != nil && ! spec.date_time.empty? then
      set_date_time spec
    end
    @duration = duration_from_spec spec if spec.duration
    @location = spec.location if spec.location
  end

  protected

  def set_fields spec
    super spec
    if spec.date_time != nil && ! spec.date_time.empty? then
      set_date_time spec
    else
      $log.warn "date_time is not set in #{formal_type} #{self.handle}"
    end
    @duration = duration_from_spec spec
    @location = spec.location
    # Prevent use of appointments with nil @date_time:
    if @date_time == nil then
      @valid = spec.is_template?
    end
  end

  def set_date_time spec
    begin
      date_parser = DateParser.new([spec.date_time])
      dates = date_parser.result
      if dates != nil && ! dates.empty? then
        @date_time = dates[0]
      end
    rescue Exception => e
      $log.warn "#{handle}: date_time invalid (#{spec.date_time}): #{e}"
      @valid = spec.is_template?
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
    "#{APPOINTMENT}: "
  end

  def current_message_subject
    "#{title} [#{handle}]"
  end

  def current_message
    result = "title: #{title}\n" + "date_time: " +
      time_24hour(date_time) + "\n" +
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

  ###  class invariant

  def invariant
    @date_time != nil and super
  end

end
