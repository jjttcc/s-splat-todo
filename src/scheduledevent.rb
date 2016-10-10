# Events scheduled at a specific date and time
class ScheduledEvent
  include ActionTarget

  attr_reader :date_time, :duration, :location

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
end
