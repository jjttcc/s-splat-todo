require 'externaldateparser'

# Parser that takes a set of date/time strings and produces a set, in
# 'result', of resulting Time objects.  If 'suppress_exception' is true, no
# exception is raised if parsing of one or more of the date/time strings
# fails due to an invalid date/time string - instead, 'result' (an Array)
# will contain a nil value for each element of the supplied date/time array
# that fails to parse.
class DateParser
  public

  attr_reader :result, :error

  private

  def initialize(datetimes, suppress_exception = false)
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
    @result.concat(dates_from_outside(datestring_array, suppress_exception))
  end

  def dates_from_outside(datetimes, suppress_exception)
    xparser = ExternalDateParser.new(datetimes)
    result = xparser.result
    if ! result or xparser.parse_failed then
      if ! xparser.error_msg.nil? && ! xparser.error_msg.empty? then
        @error = xparser.error_msg
      else
        @error = "parse failed for date(s): #{datetimes}"
      end
      if not suppress_exception then
        raise @error
      end
    end
    result
  end

end
