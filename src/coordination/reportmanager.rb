require 'preconditionerror'
require 'timetools'

# Manager of reporting-related actions
class ReportManager
  include TimeTools, ErrorTools

  public

  attr_accessor :manager

  # List info about the targets with the specified handles.
  def list_targets(short = true, handles)
    targets = targets_for(handles)
    targets.each do |t|
      if short then
        puts "#{t.handle}: #{t.title}"
      else
        puts target_info(t, handles && !handles.empty?)
      end
    end
  end

  # List the handle for all targets.
  def list_handles
    targets = manager.existing_targets.values.sort
    targets.each do |t|
      puts "#{t.handle}"
    end
  end

  # Report all descendants (child targets, their children, ...) for each
  # target whose handle is in `handles'.
  def report_targets_descendants handles
    targets = targets_for(handles)
    targets.each do |t|
      if t.can_have_children? then
        report_descendants(t, ! handles.empty?)
      else
        puts "#{t.handle} (cannot have children), due: #{time_24hour(t.time)}"
      end
    end
  end

  # List info about the targets with the specified handles.
  def report_complete handles
    targets = targets_for(handles)
    report_array = targets.map do |t|
      result = t.to_s
      if t.can_have_children? then
        result += "children: "
        children = t.children.map do |child|
          child.handle
        end
        result += children.join(', ') + "\n"
      end
      result
    end
    puts report_array.join("\n")
  end

  # List the first upcoming reminder - or if 'all', all reminders - for the
  # targets with the specified handles, or if 'handles' is nil, for all
  # targets.  If 'short', the handle, instead of the title, will be
  # included in the report for the selected targets.
  def report_reminders(all: false, handles: [], short: false)
    targets = targets_for(handles)
    tgt_w_rem = targets.select do |t|
      ! t.reminders.empty?
    end
    report_items = tgt_w_rem.map do |t|
      ReminderReportItem.new(t, all, short)
    end
    puts report_items.sort.join("\n")
  end

  # List the first upcoming reminder for the targets with the specified
  # handles, or if 'handles' is nil, for all targets.
  def report_due(handles)
    targets_due = targets_for(handles).sort.map do |t|
      TargetDue.new(t)
    end
    puts targets_due.join("\n")
  end

  private

  def initialize manager
    self.manager = manager
  end

  # precondition: target.can_have_children?
  def report_descendants target, ignore_parent = false
    assert_precondition('target.can_have_children?') {
      target.can_have_children? }
    # To prevent redundancy, only report descendants for the top-level
    # ancestor.
    if ignore_parent or ! target.has_parent? then
      puts target.descendants_report
    end
  end

  def target_info t, include_children = false
    cutoff = include_children ? -1 : 1
    tree = TreeNode.new(t)
    # Append to 'result' t's info and that of all of its descendants.
    result = tree.descendants_report(0, cutoff) do |t, level|
      toplevel = (level != nil && level == 0)
      title = toplevel ? t.title : "#{t.title[0..13]}.."
      bl_result = "[#{t.handle}] #{title}; "
      if t.time != nil then
        bl_result += "time: #{time_24hour(t.time)};"
      end
      if toplevel then
        if t.priority then bl_result += "priority: #{t.priority}; " end
        if ! t.categories.empty? then
          bl_result += "cats: " + t.categories.join(',')
        end
      end
      bl_result += " (#{t.formal_type})"
    end
    result
  end

  def targets_for handles, sorted = true
    result = manager.existing_targets.values
    if handles != nil && handles.length > 0 then
      result = []
      handles.each do |h|
        if manager.existing_targets[h] then
          result << manager.existing_targets[h]
        end
      end
    end
    if sorted then
      result.sort! do |a, b|
        time_comparison(a, b)
      end
    end
    result
  end

  def time_comparison(a, b)
    result = -2
    if a.time == nil then
      result = b.time == nil ? 0 : 1
    elsif b.time == nil then
      result = -1
    else
      result = a.time <=> b.time
    end
    result
  end

  class ReminderReportItem
    include Comparable
    public
    attr_accessor :target, :use_all_reminders, :first_reminder, :prefix,
      :suffix
    def <=>(other)
      first_reminder <=> other.first_reminder
    end
    def to_s
      result = ""
      if use_all_reminders then
        times = target.reminders.map do |r|
          r.date_time.strftime("%Y-%m-%d %H:%M")
        end
        result = "#{target.handle} - " + times.join(', ')
      else
        name = @use_handle ? target.handle : target.title
        result = prefix + first_reminder.date_time.strftime("%Y-%m-%d %H:%M") +
          + suffix + " - #{name}"
      end
      result
    end
    private
    def initialize(t, all = false, print_handle)
      if t == nil or t.reminders.empty? then
        raise "code defect - invalid target: #{t.inspect}"
      end
      @target = t
      @use_all_reminders = all
      @prefix = " "
      @suffix = " "
      @first_reminder = first_rem
      @use_handle = print_handle
    end
    def first_rem
      result = @target.reminders.first
      if ! use_all_reminders then
        result = @target.upcoming_reminders.first
        if result == nil then # The last reminder is in the past.
          result = @target.reminders.last
          @prefix = "("
          @suffix = ")"
        end
      end
      result
    end
  end

  class TargetDue
    attr_accessor :target
    public
    def to_s
      result = ""; time = ""
      if @target.time == nil then
        time = "(no due date)   "
      else
        time = @target.time.strftime("%Y-%m-%d %H:%M")
      end
      result = @prefix + time + @suffix + " - #{target.title}" +
        " (#{target.formal_type}:#{target.handle})"
      result
    end

    private
    def initialize(t)
      @target = t
      @prefix = " "
      @suffix = " "
      time = @target.time
      if time != nil and time < Time.now then
        @prefix = "("
        @suffix = ")"
      end
    end
  end

end
