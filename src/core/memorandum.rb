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
        @final_reminder = Reminder.new(expiration_date)
    end
    @final_reminder
  end

  def to_s_appendix
    "#{EXPIRATION_DATE_KEY}: #{expiration_date}\n"
  end

  ###  Status report

  def spec_type; "note" end

  ###  Element change

  def modify_fields spec
    super spec
    if spec.expiration_date != nil then
      set_expiration_date spec
    end
  end

  protected

  def set_fields spec
    super spec
    if spec.expiration_date != nil then
      set_expiration_date spec
    end
  end

  private

  def set_expiration_date spec
    begin
      @expiration_date = Time.parse(spec.expiration_date)
    rescue ArgumentError => e
      # spec.expiration_date is invalid, so leave @expiration_date as nil.
      $log.warn "expiration_date invalid [#{e}] (#{spec.expiration_date}) " +
        "in #{self}"
    end
  end

  ### Hook routine implementations

  def message_subject_label
    "memo: "
  end

  def current_message_subject
    "#{title} [#{handle}]"
  end

  def current_message
    result =
    "title: #{title}\n" +
    "type: #{formal_type}\n" +
    "expiration_date: #{expiration_date}\n"
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

  ###  Persistence

  def marshal_dump
    result = super
    result.merge!({
      'expiration_date' => expiration_date,
      'final_reminder' => final_reminder
    })
    result
  end

  def marshal_load(data)
    super(data)
    @expiration_date = data['expiration_date']
    @final_reminder = data['final_reminder']
  end

end
