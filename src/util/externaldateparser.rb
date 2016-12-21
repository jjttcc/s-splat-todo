require 'spectools'

# Date parser that uses an external command to parse a set of date/times
# ('datestrings'), producing a Time object, in 'result', for each parsed
# date/time; any parse operation that fails results in a nil value in 'result'
# (Array) in the position that corresponds (in the 'datestrings' argument
# to "new") to the date-string that failed to parse.
class ExternalDateParser
  include SpecTools

  public

  attr_reader :error_msg, :result
  # Did parsing of at least one element of 'datestrings' (passed to 'new') fail?
  attr_reader :parse_failed

  private

  EXTERNAL_EXE_PATH = 'dates.pl'
  DATE_SEPARATOR    = "\a"

  def initialize(datestrings)
    @result = []
    @error_msg = ""
    @parse_failed = false
    spth = ENV[STODO_PATH]
    @exe_path = spth + File::SEPARATOR + EXTERNAL_EXE_PATH
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

  PARSE_FAIL_FLAG = '<failed>'

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
          if d == PARSE_FAIL_FLAG then
            @result << nil
            @parse_failed = true
          else
            @result << Time.parse(d)
          end
        end
      end
    rescue Exception => e
      @error_msg = "external command #{@exe_path} failed (#{e})."
      @parse_failed = true
    end
  end

end
