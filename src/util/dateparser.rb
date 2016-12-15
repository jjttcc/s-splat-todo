class ExternalDateParser

  public

  attr_reader :error_msg, :result
  # Did parsing of date strings (invoked by 'new') fail?
  attr_reader :parse_failed

  private

  EXTERNAL_EXE_PATH = 'dates.pl'
  DATE_SEPARATOR    = "\a"

  def initialize(datestrings)
    @result = []
    @error_msg = ""
    @parse_failed = false
    @exe_path = Dir.pwd + File::SEPARATOR + EXTERNAL_EXE_PATH
    if File.executable?(@exe_path) then
      set_dates_from_external_command(datestrings)
    else
      @parse_failed = true
      if File.exist?(@exe_path) then
        @error_msg = "date parser #{@exe_path} is not executable."
      else
        @error_msg = "date parser #{@exe_path} not found."
      end
    end
  end

  # Append to @result by executing @exe_path with 'datestrs' as an argument.
  def set_dates_from_external_command(datestrs)
    begin
      cmd = [@exe_path] + datestrs
      pipe = IO.popen({}, cmd)
      response = pipe.readlines
      pipe.close
      response.each do |datesline|
        date_strs = datesline.chomp.split(DATE_SEPARATOR)
        date_strs.each do |d|
          @result << Time.parse(d)
        end
      end
    rescue Exception => e
      @error_msg = "external command #{@exe_path} failed (#{e})."
      @parse_failed = true
    end
  end

end

class DateParser
  public

  attr_reader :result

  private

  def initialize(datetimes)
    @result = []
    datestring_array = []
    datetimes.each do |dt|
      if dt.is_a?(String) then
        datestring_array << dt
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
    @result.concat(dates_from_outside(datestring_array))
  end

  def dates_from_outside(datetimes)
    xparser = ExternalDateParser.new(datetimes)
    result = xparser.result
    if ! result or xparser.parse_failed then
      error = (xparser.error_msg != nil) ? xparser.error_msg :
        "parse failed for date(s): #{datetimes}"
      raise error
    end
    result
  end

end
