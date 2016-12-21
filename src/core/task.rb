require 'stodotarget'

# Tasks - i.e., definable pieces of work to be completed by a due date
class Task < STodoTarget
  include ErrorTools

  public

  attr_reader :due_date

  ###  Access

  def time
    due_date
  end

  def final_reminder
    if @final_reminder == nil and due_date != nil then
        @final_reminder = OneTimeReminder.new(due_date)
    end
    @final_reminder
  end

  def to_s_appendix
    "#{DUE_DATE_KEY}: #{time_24hour(due_date)}\n"
  end

  ###  Status report

  def spec_type; TASK end

  def formal_type
    "Task"
  end

  private

  def set_fields spec
    super spec
    if spec.due_date != nil && ! spec.due_date.empty? then
      set_due_date spec
    end
  end

  def set_due_date spec
    begin
      date_parser = DateParser.new([spec.due_date])
      dates = date_parser.result
      if dates != nil && ! dates.empty? then
        @due_date = dates[0]
      end
    rescue Exception => e
      $log.warn "#{handle}: due_date invalid (#{spec.due_date}): #{e}"
      @valid = spec.is_template?
    end
  end

  ### Hook routine implementations

  def main_modify_fields spec
    super spec
    if spec.due_date != nil && ! spec.due_date.empty? then
      set_due_date spec
    end
  end

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

end
