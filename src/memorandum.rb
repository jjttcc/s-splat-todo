require_relative 'stodotarget'

# Notes/memoranda to be recorded, for the purpose of aiding memory and/or
# items to be reminded of at a future date.
class Memorandum < STodoTarget

  # The date, if any, for which the Memorandum is no longer of interest
  attr_reader :expiration_date

  alias :synopsis :description

  protected

  def set_fields spec
    super spec
    if spec.expiration_date != nil then
      begin
        @expiration_date = DateTime.parse(spec.expiration_date)
      rescue ArgumentError => e
        # spec.expiration_date is invalid, so leave @expiration_date as nil.
        $log.warn "expiration_date invalid [#{e}] (#{spec.expiration_date}) " +
          "in #{self}"
      end
    end
  end

  private

  ### Hook routine implementations

  def email_subject
    "memo notification: #{handle}" + subject_suffix
  end

  def email_body
    "title: #{title}\n" +
    "type: #{formal_type}\n" +
    "expiration_date: #{expiration_date}\n" +
    "description: #{memo_description}\n"
  end

  ### Implementation - utilities

  def memo_description
    result = (content != nil)? content: ""
    result += (comment != nil)? "\n" + comment: ""
    result
  end

end
