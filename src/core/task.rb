require 'stodotarget'

# Tasks - i.e., definable pieces of work to be completed by a due date
class Task < STodoTarget
  include ErrorTools

  public

  attr_reader :due_date, :completion_date

  ###  Access

  def time
    due_date
  end

  def final_reminder
    if @final_reminder == nil and due_date != nil then
        @final_reminder = Reminder.new(due_date)
    end
    @final_reminder
  end

  def to_s_appendix
    "#{DUE_DATE_KEY}: #{time_24hour(due_date)}\n"
  end

  ###  Status report

  def spec_type; TASK end

  # Has 'self' been completed?
  def completed?
    self.completion_date != nil
  end

  def formal_type
    "Task"
  end

  ###  Element change

  def modify_fields spec
    super spec
    if spec.due_date != nil then
      set_due_date spec
    end
  end

  private

  def set_fields spec
    super spec
    if spec.due_date != nil then
      set_due_date spec
    end
  end

  def set_due_date spec
    begin
      @due_date = Time.parse(spec.due_date)
    rescue ArgumentError => e
      # spec.due_date is invalid, so leave @due_date as nil.
      $log.warn "due_date invalid [#{e}] (#{spec.due_date}) in #{self}"
    end
  end

  ### Hook routine implementations

  def message_subject_label
    "todo: "
  end

  def current_message_subject
    "#{title} [#{handle}]"
  end

  def current_message
    result =
    "title: #{title}\n" +
    "due_date: #{time_24hour(due_date)}\n" +
    "type: #{formal_type}\n"
    if priority then
      result += "priority: #{priority}\n"
    end
    result += "description: #{content}\n"
    result
  end

  def set_cal_fields calentry
    super calentry
    calentry.time = due_date
  end

  ###  Persistence

  def old_remove__marshal_dump
    result = super
    result.merge!({
      'due_date' => due_date,
      'completion_date' => completion_date,
      'final_reminder' => final_reminder
    })
    result
  end

  def old_remove__marshal_load(data)
    super(data)
    @due_date = data['due_date']
    @completion_date = data['completion_date']
    @final_reminder = data['final_reminder']
  end

end
