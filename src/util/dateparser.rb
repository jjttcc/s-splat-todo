class ExternalDateParser

  public

  attr_reader :error_msg, :result

  private

  EXTERNAL_EXE_PATH = 'dates.pl'

  def initialize(datestring)
    @error_msg = ""
    @exe_path = Dir.pwd + File::SEPARATOR + EXTERNAL_EXE_PATH
    if File.executable?(@exe_path) then
$log.debug "calling set_date_from_external_command with '#{datestring}'"
      set_date_from_external_command(datestring)
$log.debug "back from set_date_from_external_command result: #{@result}"
    else
      if File.exist?(@exe_path) then
        @error_msg = "date parser #{@exe_path} is not executable."
      else
        @error_msg = "date parser #{@exe_path} not found."
      end
    end
  end

  # Set @result by executing @exe_path with 'datestr' as an argument.
  def set_date_from_external_command(datestr)
    require 'open3'
    @result = nil
    output, error, status = Open3::capture3(@exe_path, datestr)
$log.debug "ecr - outp, err, status: #{output}, #{error}, #{status.inspect}"
    if status.success? then
      begin
        @result = Time.parse(output.chomp)
$log.debug "ecr - outp, result: #{output.chomp}, #{@result}"
      rescue ArgumentError => e
        @error_msg = "date/time invalid"
      end
    else
      @error_msg = "external command #{@exe_path} failed."
      if error then
        @error_msg += " (#{error})"
      end
    end
  end

end

class DateParser
  public

  attr_reader :result

  private

  def initialize(datetimes)
    @result = []
    datetimes.each do |dt|
      if dt.is_a?(String) then
        current_dt = date_from_outside(dt)
        if current_dt == nil then
          msg = "Bad datetime: #{dt}"
          if @external_error then
            msg += " - '#{@external_error}'"
          end
          raise msg
        else
          @result << current_dt
        end
      else
        if dt.is_a?(Time) then
          @result << dt
        else
          msg = 'DateParser.new: '
          if dt == nil then
            msg += "datetime argument is nil"
          else
            msg += "datetime argument is not a Time (#{dt.class})"
          end
          raise msg
        end
      end
    end
  end

  def old_old___initialize(datetimes)
    if datetime.is_a?(String) then
      @result = date_from_outside(datetime)
      if @result == nil then
        msg = "Bad datetime: #{datetime}"
        if @external_error then
          msg += " - '#{@external_error}'"
        end
        raise msg
      end
    else
      if datetime.is_a?(Time) then
        @result = datetime
      else
        msg = 'DateParser.new: '
        if datetime == nil then
          msg += "datetime argument is nil"
        else
          msg += "datetime argument is not a Time (#{datetime.class})"
        end
        raise msg
      end
    end
  end

  def date_from_outside(datetime)
    xparser = ExternalDateParser.new(datetime)
    result = xparser.result
    if ! result then
$log.debug "date_from_outside - NOT result"
      @external_error = xparser.error_msg
    end
    result
  end

end
