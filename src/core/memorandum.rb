require 'stodotarget'

# Notes/memoranda to be recorded, for the purpose of aiding memory and/or
# items to be reminded of at a future date.
class Memorandum < STodoTarget

  # The date, if any, for which the Memorandum is no longer of interest
  attr_reader :expiration_date

  alias :synopsis :description

  public

  ###  Access

  def time
    result = nil
    if expiration_date != nil
      result = expiration_date
    end
    result
  end

  def final_reminder
    if @final_reminder == nil and expiration_date != nil then
        @final_reminder = OneTimeReminder.new(expiration_date)
    end
    @final_reminder
  end

  def to_s_appendix
    "#{EXPIRATION_DATE_KEY}: #{time_24hour(expiration_date)}\n"
  end

  ###  Status report

  def spec_type; NOTE end

  protected

  def set_fields spec
    super spec
    if spec.expiration_date != nil && ! spec.expiration_date.empty? then
      set_expiration_date spec
    end
  end

  private

  def main_modify_fields spec
    super spec
    if spec.expiration_date != nil && ! spec.expiration_date.empty? then
      set_expiration_date spec
    end
  end

  def set_expiration_date spec
    begin
      date_parser = DateParser.new([spec.expiration_date])
      dates = date_parser.result
      if dates != nil && ! dates.empty? then
        @expiration_date = dates[0]
      end
    rescue Exception => e
      $log.warn "#{handle}: expiration_date invalid " +
        "(#{spec.expiration_date}): #{e}"
      @valid = spec.is_template?
    end
  end

  ### Hook routine implementations

  def message_subject_label
    "#{NOTE_ALIAS2}: "
  end

  def current_message_subject
    "#{title} [#{handle}]"
  end

  def current_message
    result =
    "title: #{title}\n" +
    "type: #{formal_type}\n" +
    "expiration_date: #{time_24hour(expiration_date)}\n"
    if priority then
      result += "priority: #{priority}\n"
    end
    result += "description: #{memo_description}\n"
    result
  end

  ### Implementation - utilities

  def memo_description
    result = (content != nil)? content: ""
    result += (comment != nil)? "\n" + comment: ""
    result
  end

end
