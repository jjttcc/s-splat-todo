
# Structured entries to be submitted to an external calendar program
class CalendarEntry
  include SpecTools, Process

  attr_accessor :calendar_id, :title, :time, :location, :duration,
    :description, :invitees, :reminder_spec

  public

  # Submit a calendar entry to the configured calendar service with the
  # current settings (title, time, location, ...).
  # Note: The calendar-entry submission will be aborted if the 'time' field
  # has not been set.
  # precondition: calendar_id != nil && duration != nil && title != nil &&
  #   time != nil
  def submit
    if time != nil then
      cmd = entry_creation_command
      exec_cmd cmd
    else
      $log.warn "#{self.class}: Submission requested for item with " +
        "null 'time' field [#{self.inspect}]"
    end
    clear_fields
  end

  ###  Status report

  def inspect
    result = ""
    instance_variables.each do |attr|
      result += "#{attr}: #{instance_variable_get attr}\n"
    end
    result
  end

  private

  def initialize config
    @configuration = config
  end

  ### Implementation - utilities

  def entry_creation_command
    if duration == nil then
      # (nil duration implies "infinitely small" "meeting".)
      @duration = 1
    end
    enforce_entry_creation_preconditions
    program = @configuration.calendar_tool
    result = [program, '--calendar', calendar_id, '--title', title,
              '--when', time.strftime('%Y-%m-%d %H:%M'),
              '--duration', duration.to_s]
    if location != nil then
      result << '--where' << location
    else
      result << '--where' << ''
    end
    if description != nil then
      result << '--description' << description
    end
    if reminder_spec != nil then
      result << '--reminder' << reminder_spec
    else
      result << '--reminder' << '0'
    end
    if invitees != nil then
      result << '--who' << invitees.split(' ')
    end
    result << 'add'
    result
  end

  def exec_cmd cmd
    if @configuration.test_run? then
      $log.debug "#{self.class} Pretending to execute #{cmd}"
    else
      pid = fork
      if pid == nil then  # child
        begin
          exec(*cmd)
        rescue SystemCallError => e
          msg = "#{cmd} failed: #{e}"
          msg += ". stack trace:\n" + e.backtrace.join("\n")
          $log.error msg
          raise msg
        end
      else
        wpid, status = waitpid2(pid)
        if status.exitstatus != 0 then
          msg = "Calendar command failed with status #{status}\n[#{cmd}]"
          $log.error msg
        end
      end
    end
  end

  def clear_fields
    @calendar_id, @title, @time, @location, @duration, @description =
      nil, nil, nil, nil, nil, nil
  end

  def enforce_entry_creation_preconditions
    missing_fields = []
    if calendar_id == nil then missing_fields << "calendar_id" end
    if duration == nil then missing_fields << "duration" end
    if title == nil then missing_fields << "title" end
    if time == nil then missing_fields << "time" end
    if not missing_fields.empty? then
      raise "Fatal: calendar entry missing fields: " +
        missing_fields.join(', ')
    end
  end

  def cleaned_for_shell cmd
    result = cmd.gsub("'", %q(\\\'))
    result = result.gsub(/[()]/) {|match| "\\#{match}"}
    result
  end

end

=begin
/home/jtc/lib/python2/bin/gcalcli \
  --calendar 'jim.cochrane@gmail.com' \
  --title 'test cal "reminder"' \
  --where '[nowhere]' \
  --when '09/20/2016' \
  --duration 1 \
  --description 'test cal "reminder"' \
  --reminder 10 \
  --who jim.cochrane@gmail.com \
  add
=end
