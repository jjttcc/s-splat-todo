require_relative 'stodotarget'

# Notes/memoranda to be recorded, for the purpose of aiding memory and/or
# items to be reminded of at a future date.
class Memorandum
  include STodoTarget

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
    "expiration_date: #{expiration_date}\n" +
    "description: #{content}\n"
  end

end
