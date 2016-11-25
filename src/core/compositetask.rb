require 'time'
require 'stodotarget'
require 'treenode'

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
    "#{DUE_DATE_KEY}: #{time_24hour(due_date)}\n"
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
    tree = TreeNode.new(self)
    tree.descendants_report do |t|
      "#{t.handle}, due: #{time_24hour(t.time)}"
    end
  end

  private

  def set_fields spec
    super spec
#!!!!Suggestion: Change 'tasks' to a Set:
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
    "due_date[c]: #{time_24hour(due_date)}\n" +
    "type: #{formal_type}\n"
    if priority then
      result += "priority: #{priority}\n"
    end
    result += "description: #{content}\n"
    if ! tasks.empty? then
      result += "subtasks:\n"
      tasks.each do |t|
        tree = TreeNode.new(t)
        # Append to 'result' t's info and that of all of its descendants.
        result += tree.descendants_report(1) do |t|
          "#{time_24hour(t.time)}  #{t.title} (#{t.formal_type}:#{t.handle})"
        end
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
