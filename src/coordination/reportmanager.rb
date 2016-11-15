require 'preconditionerror'

# Manager of reporting-related actions
class ReportManager
  public

  attr_accessor :manager

  # List info about the targets with the specified handles.
  def list_targets(short = true, handles)
    targets = targets_for(handles)
    targets.each do |t|
      if short then
        puts "#{t.handle}: #{t.title}"
      else
        puts target_info(t)
      end
    end
  end

  # List the handle for all targets.
  def list_handles
    targets = manager.existing_targets.values
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
        report_descendants(t)
      else
        puts "#{t.handle} cannot have children."
      end
    end
  end

  # List info about the targets with the specified handles.
  def report_complete handles
    targets = targets_for(handles)
    report_array = targets.map { |t| t.to_s }
    puts report_array.join("\n")
  end

  # List the first upcoming reminder for the targets with the specified
  # handles, or if 'handles' is nil, for all targets.
  def report_reminders(all, handles)
    targets = targets_for(handles)
    tgt_w_rem = targets.select do |t|
      ! t.reminders.empty?
    end
    report_items = tgt_w_rem.map do |t|
      ReminderReportItem.new(t, all)
    end
    puts report_items.sort.join("\n")
  end

  private

  def initialize manager
    self.manager = manager
  end

  def report_descendants target
    # To prevent redundancy, only report descendants for the top-level
    # ancestor.
    if ! target.has_parent? then
      puts "#{target.handle}'s descendants:"
      desc = target.descendants
      desc.keys.sort.each do |k|
        indent = ' ' * (2 * k)
        desc[k].each do |t|
          puts "#{indent}#{t.handle}"
        end
      end
    end
  end

  def target_info t
    result = "[#{t.handle}] #{t.title}; "
    if t.time != nil then
      result += "time: #{t.time}; "
    end
    if t.priority then result += "priority: #{t.priority}; " end
    result += "cats: " + t.categories.join(',')
    result += " (#{t.formal_type})"
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
        result = prefix + first_reminder.date_time.strftime("%Y-%m-%d %H:%M") +
          + suffix + " - #{target.title}"
      end
      result
    end
    private
    def initialize(t, all = false)
      if t == nil or t.reminders.empty? then
        raise "code defect - invalid target: #{t.inspect}"
      end
      @target = t
      @use_all_reminders = all
      @prefix = " "
      @suffix = " "
      @first_reminder = first_rem
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

end
