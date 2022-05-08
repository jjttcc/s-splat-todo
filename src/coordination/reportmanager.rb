require 'preconditionerror'
require 'timetools'

# Manager of reporting-related actions
class ReportManager
  include TimeTools, ErrorTools

  public

  attr_accessor :manager

  # List info about the targets with the specified handles.
  def list_targets(short = true, criteria)
    targets = targets_for_criteria(criteria)
    targets.each do |t|
      if short then
        puts "#{t.handle}: #{t.title}"
      else
        puts target_info(t,
                         criteria.handles && !criteria.handles.empty?)
      end
    end
  end

  # List info about the targets with the specified handles.
  def old___list_targets(short = true, criteria)
    targets = targets_for(criteria.handles)
    targets.each do |t|
      if t.state == nil or criteria.states.include?(t) then
        if short then
          puts "#{t.handle}: #{t.title}"
        else
          puts target_info(t,
                           criteria.handles && !criteria.handles.empty?)
        end
      end
    end
  end

  # List the handle for all targets.
  # (!!!!re-spec this method, perhaps!!!!)
  def list_handles(criteria)
#!!!rm: targets = manager.existing_targets.values.sort
    if criteria.null_criteria? then
#!!!!!!^^^^^^^^^^^^^ - document this logic!!!!!
#!!!$stderr.puts "nulcrit"
      targets = targets_for(nil)
    elsif criteria.handles_only? then
#!!!$stderr.puts "honly"
      targets = targets_for(criteria.handles)
    else
#!!!$stderr.puts "NOT honly"
      targets = targets_for_criteria(criteria)
    end
    targets.each do |t|
      puts "#{t.handle}"
    end
  end

  # List the handle for all targets.
  # (!!!!re-spec this method, perhaps!!!!)
  def old___list_handles(criteria)
    targets = manager.existing_targets.values.sort
    targets.each do |t|
      if t.state == nil or criteria.states.include?(t) then
        puts "#{t.handle}"
      end
    end
  end

  # Report all descendants (child targets, their children, ...) for each
  # target whose handle is in `criteria.handles'.
  def report_targets_descendants criteria
    targets = targets_for_criteria(criteria)
    targets.each do |t|
      if t.can_have_children? then
        report_descendants(t, ! criteria.handles.empty?)
      else
        puts "#{t.handle} (cannot have children), due: #{time_24hour(t.time)}"
      end
    end
  end

  # Report all descendants (child targets, their children, ...) for each
  # target whose handle is in `criteria.handles'.
  def old___report_targets_descendants criteria
    targets = targets_for(criteria.handles)
    targets.each do |t|
      if t.can_have_children? then
        report_descendants(t, ! criteria.handles.empty?)
      else
        puts "#{t.handle} (cannot have children), due: #{time_24hour(t.time)}"
      end
    end
  end

  # List info about the targets with the specified handles and criteria.
  def report_complete criteria
#!!!$stderr.puts "#{__method__}: criteria: #{criteria.inspect}"
    if criteria.null_criteria? then
      # No criteria specified implies retrieval of all items (targets).
      targets = targets_for(nil)
    else
      targets = targets_for_criteria(criteria)
    end
#!!!$stderr.puts "targets.count: #{targets.count}"
#!!!$stderr.puts "criteria.handles_only?: #{criteria.handles_only?}"
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

  # List info about the targets with the specified handles and states.
  def old___report_complete criteria
#!!!$stderr.puts "#{__method__}: criteria: #{criteria.inspect}"
    # (Note: targets_for returns all targets if 'handles' is nil.)
    targets = targets_for(criteria.handles)
#!!!$stderr.puts "targets.count: #{targets.count}"
#!!!$stderr.puts "criteria.handles_only?: #{criteria.handles_only?}"
    if ! criteria.handles_only? then
      targets = targets.select do |t|
        criteria.priorities.include?(t.priority) &&
          (t.state == nil || criteria.states.include?(t))
      end
    end
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
  def report_reminders(all: false, handles: [], short: false, states: stts)
    targets = targets_for(handles)
    tgt_w_rem = targets.select do |t|
      ! t.reminders.empty?
    end
    report_items = (tgt_w_rem.select do |t|
      t.state == nil or states.include?(t)
    end).map do |t|
      ReminderReportItem.new(t, all, short)
    end
    puts report_items.sort.join("\n")
  end

  # List uncompleted/not-cancelled targets with their due dates.
  def report_due(criteria)
    targets_due = (targets_for(criteria.handles).select do |t|
      t.state == nil or criteria.states.include?(t)
    end).sort.map do |t|
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

  # (Note: Returns all targets if 'handles' is nil.)
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

  def targets_for_criteria criteria, sorted = true
    result = targets_for(criteria.handles, sorted)
    if ! criteria.handles_only? then
      result = result.select do |t|
        criteria.priorities.include?(t.priority) &&
          (t.state == nil || criteria.states.include?(t))
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
        times = target.reminders.sort.map do |r|
          r.date_time.strftime("%Y-%m-%d %H:%M")
        end
        result = "#{target.handle} - " + times.join('; ')
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
      result = @target.reminders.sort.first
      if ! use_all_reminders then
        result = @target.upcoming_reminders(true).first
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
