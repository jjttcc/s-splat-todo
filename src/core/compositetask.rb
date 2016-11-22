require 'time'
require 'stodotarget'

# Tasks that, optionally, contain one or more subtasks
class CompositeTask < STodoTarget

  attr_reader :due_date, :tasks, :completion_date

  public

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
    "#{DUE_DATE_KEY}: #{due_date}\n"
  end

  # All 'tasks', 'tasks' of those 'tasks', etc., recursively
  def descendants
    result = []
    tasks.each do |t|
      result << t
      if t.can_have_children? then
        result.concat(t.descendants)
      end
    end
    result
  end

  # Array of arrays such that the first element of the inner array is the
  # level at which the associated target occurs in self's descendant
  # hierarchy and the second element is the associated target
  def descendants_with_position(curpos = 0)
    result = []
    tasks.each do |t|
      result << [curpos+1, t]
      if t.can_have_children? then
        result.concat(t.descendants_with_position(curpos + 1))
      end
    end
    result
  end

  ###  Status report

  def spec_type; TASK end

  def can_have_children?
    true
  end

  # Has 'self' been completed?
  def completed?
    self.completion_date != nil
  end

  def formal_type
    "Task"
  end

  ###  Element change

  # Add a child task (to 'tasks').
  # precondition: t != nil and t.parent_handle == handle
  def add_task(t)
    if ! (t != nil and t.parent_handle == handle) then
      raise PreconditionError, 't != nil and t.parent_handle == handle'
    end
    @tasks << t
  end

  def modify_fields spec
    super spec
    if spec.due_date != nil then
      set_due_date spec
    end
    if spec.parent != nil then
      @parent_handle = spec.parent
    end
  end

  ###  Removal

  # Remove task `t' from 'tasks'.
  def remove_task t
    @tasks.delete(t)
  end

  ###  Miscellaneous

  def descendants_report
    result = {}
    desc_w_pos = descendants_with_position
    desc_w_pos.each do |d|
      arr = result[d[0]]
      if arr == nil then
        arr = []
        result[d[0]] = arr
      end
      arr << d[1]
    end
    result
  end

  private

  def set_fields spec
    super spec
    @tasks = []
    if spec.due_date != nil then
      set_due_date spec
    end
    if spec.parent != nil then
      @parent_handle = spec.parent
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
    "due_date: #{due_date}\n" +
    "type: #{formal_type}\n"
    if priority then
      result += "priority: #{priority}\n"
    end
    result += "description: #{content}\n"
    desc = descendants
    if ! desc.empty? then
      result += "subtasks:\n"
      descendants.each do |subt|
        time = subt.time
        time ||= ' ' * 16
        result +=
          "#{time} #{subt.title} (#{subt.formal_type}:#{subt.handle})\n"
      end
    end
    result
  end

  def set_cal_fields calentry
    super calentry
    calentry.time = due_date
  end

  ###  Persistence

  def marshal_dump
    result = super
    result.merge!({
      'due_date' => due_date,
      'tasks' => tasks,
      'completion_date' => completion_date,
      'final_reminder' => final_reminder
    })
    result
  end

  def marshal_load(data)
    super(data)
    @due_date = data['due_date']
    @tasks = data['tasks']
    @completion_date = data['completion_date']
    @final_reminder = data['final_reminder']
  end

end
