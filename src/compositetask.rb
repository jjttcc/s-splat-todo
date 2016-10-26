require 'date'
require_relative 'stodotarget'

# Tasks that, optionally, contain one or more subtasks
class CompositeTask < STodoTarget

  attr_reader :due_date, :tasks, :completion_date

  public

  ###  Element change

  # Add a child task.
  # precondition: t != nil and t.parent_handle == handle
  def add_task(t)
    if ! (t != nil and t.parent_handle == handle) then
      raise PreconditionError, 't != nil and t.parent_handle == handle'
    end
    @tasks << t
  end

  ###  Status report

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

  ###  Miscellaneous

  def descendants level = 0
    result = {}
    if tasks then
      result[level + 1] = tasks
    end
    tasks.each do |t|
      result.merge!(t.descendants(level + 1))
    end
    result
  end

  private

  def set_fields spec
    super spec
    @tasks = []
    if spec.due_date != nil then
      begin
        @due_date = DateTime.parse(spec.due_date)
      rescue ArgumentError => e
        # spec.due_date is invalid, so leave @due_date as nil.
        $log.warn "due_date invalid [#{e}] (#{spec.due_date}) in #{self}"
      end
    end
    if spec.parent != nil then
      @parent_handle = spec.parent
$log.debug "ph: #{@parent_handle}"
    end
  end

  ### Hook routine implementations

  def email_subject
    "task notification: #{handle}" + subject_suffix
  end

  def email_body
    "title: #{title}\n" +
    "due_date: #{due_date}\n" +
    "type: #{formal_type}\n" +
    "description: #{content}\n"
  end

  def set_cal_fields calentry
    super calentry
    calentry.time = due_date
  end

end
