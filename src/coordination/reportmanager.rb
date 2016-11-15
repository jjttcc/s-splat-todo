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
    report_array = targets.map do |t|
      remtimes = []; reminders = []
      line = "#{t.handle}"
      if all then
        line += ": "
        reminders = t.reminders
      else
        line += "\t"
        reminders = t.upcoming_reminders.first(1)
      end
      remtimes = reminders.map do |r|
        r.date_time.strftime("%Y-%m-%d %H:%M")
      end
      line + remtimes.join('; ')
    end
    puts report_array.join("\n")
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

end
