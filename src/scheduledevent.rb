# Events scheduled at a specific date and time
class ScheduledEvent < STodoTarget

  attr_reader :date_time, :duration, :location

  public

  def formal_type
    "Appointment"
  end

  protected

  def set_fields spec
    super spec
    if spec.date_time != nil then
      begin
        @date_time = DateTime.parse(spec.date_time)
      rescue ArgumentError => e
        # spec.date_time is invalid, so leave @date_time as nil.
        $log.warn "date_time invalid [#{e}] (#{spec.date_time}) " +
          "in #{self}"
      end
    end
    @duration = duration_from_spec spec
    @location = spec.location
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
    result = "title: #{title}\n" + "date_time: #{date_time}\n" +
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

end
