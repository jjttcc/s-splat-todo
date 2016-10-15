require 'date'
require_relative 'stodotarget'

# Tasks that, optionally, contain one or more subtasks
class CompositeTask < STodoTarget

  attr_reader :due_date, :parent_handle, :tasks, :completion_date

  public

  ###  Element change

  def add_task(t)
    @tasks << t
  end

  ###  Status report

  # Does 'self' have a parent?
  def has_parent?
    self.parent_handle != nil
  end

  # Has 'self' been completed?
  def completed?
    self.completion_date != nil
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
    if spec.parent_handle != nil then
      @parent_handle = spec.parent_handle
    end
  end

  ### Hook routine implementations

  def email_subject
    "task notification: #{handle}" + subject_suffix
  end

  def email_body
    "title: #{title}\n" +
    "due_date: #{due_date}\n" +
    "description: #{content}\n"
  end

  def set_cal_fields calentry
    super calentry
    calentry.time = due_date
  end

end
