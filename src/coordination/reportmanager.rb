require 'ruby_contracts'
require 'preconditionerror'
require 'spectools'
require 'timetools'
require 'stodogit'

# Manager of reporting-related actions
class ReportManager
  include SpecTools, TimeTools, ErrorTools
  include Contracts::DSL

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

  # List the handle for all targets that match 'criteria'.
  def list_handles criteria
    if criteria.null_criteria? then
      # (No criteria implies reporting on all targets.)
      targets = targets_for(nil)
    elsif criteria.handles_only? then
      targets = targets_for(criteria.handles)
    else
      targets = targets_for_criteria(criteria)
    end
    targets.each do |t|
      puts "#{t.handle}"
    end
  end

  # List all handles currently in the git repository.
  # ('criteria' is currently not used.)
  def list_git_handles criteria
    # (Ignore 'criteria' [might never be used].)
    Configuration.instance.stodo_git.list_handles
  end

  # Output all log entries for the items/handles specified by 'criteria'
  # currently in the git repository.
  def show_git_log criteria
    handles = nil
    if ! criteria.null_criteria? then
      if criteria.handles_only? then
        handles = criteria.handles
      else
        handles = targets_for_criteria(criteria).map do |t|
          t.handle
        end
      end
    end
    Configuration.instance.stodo_git.show_git_log handles
  end

  # Obtain the specified version (according to git_commit_id) of the
  # specified items (from criteria) and output their contents to stdout.
  def show_git_items criteria
    commit_id = git_commit_id
    if commit_id.nil? || commit_id.empty? then
      raise "git-ret: #{no_commit_id_msg}"
    end
    handles = []
    if ! criteria.null_criteria? then
      if criteria.handles_only? then
        handles = criteria.handles
      else
        handles = targets_for_criteria(criteria).map do |t|
          t.handle
        end
      end
    end
    Configuration.instance.stodo_git.show_git_version(commit_id, handles)
  end

  def show_description criteria
    if criteria.null_criteria? then
      # (No criteria implies reporting on all targets.)
      targets = targets_for(nil)
    elsif criteria.handles_only? then
      targets = targets_for(criteria.handles)
    else
      targets = targets_for_criteria(criteria)
    end
    verbose = targets.count > 1
    targets.each do |t|
      if verbose then puts "\n[#{t.handle}]:" end
      puts t.description
    end
  end

  def show_t_description criteria
    if criteria.null_criteria? then
      # (No criteria implies reporting on all targets.)
      targets = targets_for(nil)
    elsif criteria.handles_only? then
      targets = targets_for(criteria.handles)
    else
      targets = targets_for_criteria(criteria)
    end
    verbose = targets.count > 1
    targets.each do |t|
      if verbose then
        puts "\n[#{t.handle}]:"
        puts "title: #{t.title}"
      else
        puts "#{t.title}:"
      end
      puts t.description
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

  # Report the handle of the parent of each target that matches 'criteria'.
  def report_parent criteria
    targets = targets_for_criteria(criteria)
    verbose = targets.count > 1
    targets.each do |t|
      if verbose then
        print "#{t.handle}: "
      end
      if t.parent_handle.nil? then
        puts "{no-parent}"
      else
        puts t.parent_handle
      end
    end
  end

  # "Process" all attachments for the items specified in 'criteria'.
  def report_attachments criteria
    config = Configuration.instance
    if criteria.null_criteria? then
      # No criteria specified implies retrieval of all items (targets).
      targets = targets_for(nil)
    else
      targets = targets_for_criteria(criteria)
    end
    editing = config.edit_attachment
    targets.each do |t|
      t.process_attachments editing
    end
  end

  # Report all descendants (child targets, their children, ...) for each
  # target whose handle is in `criteria.handles'.
  def report_emancipated_children criteria
    targets = targets_for_criteria(criteria)
    verbose = targets.count > 1
    indent = verbose ? '   ': ''
    targets.each do |t|
      if verbose then
        print "#{t.handle}:"
      end
      if t.can_have_children? then
        if verbose then print "\n#{indent}" end
        tlist = t.emancipated_children
        puts tlist.map { |t| t.handle }.join("\n#{indent}")
      else
        puts "(#{t.handle} cannot have children), due: #{time_24hour(t.time)}"
      end
    end
  end

  # Report all descendants (child targets, their children, ...) for each
  # target whose handle is in `criteria.handles'.
  def report_emancipated_descendants criteria
    targets = targets_for_criteria(criteria)
    targets.each do |t|
      if t.can_have_children? then
        tlist = t.emancipated_descendants
        puts tlist.map { |t| t.handle }.join("\n")
      else
        puts "#{t.handle} (cannot have children), due: #{time_24hour(t.time)}"
      end
    end
  end

  # Report the duration of self at this point in time in hours:
  #   ! completion_time.nil? -> (completion_time - creation_time) / 360
  #   completion_time.nil?   -> (now - creation_time) / 360
  def report_duration criteria
    targets = targets_for_criteria(criteria)
    fmt_time = lambda do |t| t.strftime("%Y-%m-%d %H:%M") end
    targets.each do |t|
      start_time = t.creation_date
      end_time = t.completion_date
      if end_time.nil? then
        end_time = Time.now
      end
      print "'#{t.handle}' duration in hours: "
      printf "%.4f\n", (end_time - start_time) / 3600
      printf "   (start_time: %s, end_time: %s)\n",
        fmt_time.call(start_time), fmt_time.call(end_time)
    end
  end

  # List info about the targets with the specified handles and criteria.
  def report_complete criteria
    if criteria.null_criteria? then
      # No criteria specified implies retrieval of all items (targets).
      targets = targets_for(nil)
    else
      targets = targets_for_criteria(criteria)
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
  # targets with the specified criteria, or if: 'criteria.null_criteria?' or
  # 'criteria' == nil, for all targets with reminders.  If 'short', the
  # handle, instead of the title, will be included in the report for the
  # selected targets.
  def report_reminders(all: false, criteria: nil, short: false)
    targets = targets_for_criteria(criteria)
    tgt_w_rem = targets.select do |t|
      ! t.reminders.empty?
    end
    report_items = tgt_w_rem.map do |t|
      ReminderReportItem.new(t, all, short)
    end
    puts report_items.sort.join("\n")
  end

  # List uncompleted/not-cancelled targets with their due dates.
  def report_due criteria
    if criteria.null_criteria? then
      # (No criteria implies reporting on all targets.)
      targets = targets_for(nil)
    elsif criteria.handles_only? then
      targets = targets_for(criteria.handles)
    else
      targets = targets_for_criteria(criteria)
    end
    targets_due = targets.sort.map do |t|
      TargetDue.new(t)
    end
    puts targets_due.join("\n")
  end

  # Report service names used for logging.
  def report_service_names
    config = Configuration.instance
    puts config.log_config.service_names
  end

  # Report "log keys", created during logging, that match 'criteria'.
  def report_logkeys(criteria)
    config = Configuration.instance
    puts config.log_config.log_keys(criteria.handles[0])
  end

  # Report the list of all log keys for the current user.
  def report_logkey_list(criteria)
    config = Configuration.instance
    puts config.log_config.log_key_list(criteria)
  end

  def report_logmsgs(criteria)
    config = Configuration.instance
    puts config.log_config.log_messages(criteria.handles[0])
  end

  def report_tranaction_logs(transaction_id)
    config = Configuration.instance
    log_entries = config.transaction_log.log_messages(transaction_id)
#!!!to-do: format this:
    puts "#{log_entries.count} log entries:\n" + log_entries.join("\n")
  end

  def report_tranaction_ids
    config = Configuration.instance
    ids = config.transaction_log.transaction_ids
    puts "#{ids.count} ids:\n" + ids.join("\n")
  end

  private

  def initialize manager
    self.manager = manager
    create_compare_methods
  end

  pre 'target.can_have_children?' do |target| target.can_have_children?  end
  def report_descendants target, ignore_parent = false
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
    if handles != nil && handles.length > 0 then
      result = []
      handles.each do |h|
        if manager.existing_targets[h] then
          result << manager.existing_targets[h]
        end
      end
    else
      result = manager.existing_targets.values
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
    if ! criteria.null_criteria? && ! criteria.handles_only? then
      apply_criteria = comparison_method(criteria)
      result = result.select do |t|
        apply_criteria.call(t, criteria)
      end
    end
    result
  end

  # Create the table of lambdas (comparison_method_table) to use for
  # criteria comparison.
  def create_compare_methods
    @comparison_method_table = {}
    pri_cmp = lambda {|tgt, crit|
      crit.priorities.include?(tgt.priority)
    }
    sta_cmp = lambda {|tgt, crit|
      tgt.state == nil || crit.states.include?(tgt)
    }
    typ_cmp = lambda {|tgt, crit|
      tgt.type == nil || crit.types.include?(tgt.type)
    }
    ttl_cmp = lambda {|tgt, crit|
      crit.title_exprs.any? { |e|
      Regexp.new(e, Regexp::IGNORECASE).match(tgt.title) }
    }
    hnd_cmp = lambda {|tgt, crit|
      crit.handle_exprs.any? { |e|
      Regexp.new(e, Regexp::IGNORECASE).match(tgt.handle) }
    }
    des_cmp = lambda {|tgt, crit|
      crit.description_exprs.any? { |e|
      Regexp.new(e, Regexp::IGNORECASE).match(tgt.description) }
    }

    @comparison_method_table[PRI] = pri_cmp
    @comparison_method_table[STATE] = sta_cmp
    @comparison_method_table[TYPE] = typ_cmp
    @comparison_method_table[TITLE] = ttl_cmp
    @comparison_method_table[HANDLE] = hnd_cmp
    @comparison_method_table[DESCRIPTION] = des_cmp

    [PRI, STATE, TITLE, HANDLE, DESCRIPTION].each do |k|
      [STATE, TITLE, HANDLE, DESCRIPTION].each do |l|
        if l == k then
          # Prevent key duplications.
          break
        end
        [TITLE, HANDLE, DESCRIPTION].each do |m|
          if m == l || m == k then
            # Prevent key duplications.
            break
          end
          [HANDLE, DESCRIPTION].each do |n|
            if n == m || n == l || n == k then
              # Prevent key duplications.
              break
            end
            # 4-element combinations of k + <remaining-keys>:
            mtbl_key = standardized_key_combo([k, l, m, n])
            @comparison_method_table[mtbl_key] = lambda {|tgt, crit|
              @comparison_method_table[k].call(tgt, crit) &&
                @comparison_method_table[l].call(tgt, crit) &&
                @comparison_method_table[m].call(tgt, crit) &&
                @comparison_method_table[n].call(tgt, crit)
            }
            [DESCRIPTION].each do |o|
              if o == n || o == m || o == l || o == k then
                # Prevent key duplications.
                break
              end
              # 5-element combinations of k + <remaining-keys>:
              mtbl_key = standardized_key_combo([k, l, m, n, o])
              @comparison_method_table[mtbl_key] = lambda {|tgt, crit|
                @comparison_method_table[k].call(tgt, crit) &&
                  @comparison_method_table[l].call(tgt, crit) &&
                  @comparison_method_table[m].call(tgt, crit) &&
                  @comparison_method_table[n].call(tgt, crit) &&
                  @comparison_method_table[o].call(tgt, crit)
              }
            end
          end
          # 3-element combinations of k + <remaining-keys>:
          mtbl_key = standardized_key_combo([k, l, m])
          @comparison_method_table[mtbl_key] = lambda {|tgt, crit|
            @comparison_method_table[k].call(tgt, crit) &&
              @comparison_method_table[l].call(tgt, crit) &&
              @comparison_method_table[m].call(tgt, crit)
          }
        end
        # 2-element combinations of k + <remaining-keys>:
        mtbl_key = standardized_key_combo([k, l])
        @comparison_method_table[mtbl_key] = lambda {|tgt, crit|
          @comparison_method_table[k].call(tgt, crit) &&
            @comparison_method_table[l].call(tgt, crit)
        }
      end
    end
  end

  # "type-spec" keys
  PRI, STATE, TITLE, HANDLE, DESCRIPTION, TYPE = 'pri', 'state', 'title',
    'handle', 'description', 'type'

  attr_reader :comparison_method_table

  def comparison_method(criteria)
    pri_key, stat_key, ttl_key, hndl_key, des_key = '', '', '', '', ''
    if criteria.has_priorities? then
      pri_key = PRI
    end
    if criteria.has_states? then
      stat_key = STATE
    end
    if criteria.has_types? then
      stat_key = TYPE
    end
    if criteria.has_title_exprs? then
      ttl_key = TITLE
    end
    if criteria.has_handle_exprs? then
      hndl_key = HANDLE
    end
    if criteria.has_description_exprs? then
      des_key = DESCRIPTION
    end
    key = standardized_key_combo(
      [pri_key, stat_key, ttl_key, hndl_key, des_key])
    comparison_method_table[key]
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

  # A "standardized" (i.e., sorted) concatenation of the keys in 'array'
  def standardized_key_combo(array)
    result = ""
    array.sort.each do |k|
      if ! k.empty? then
        result << k
      end
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
        file_line = "\n(file #{__FILE__}, line #{__LINE__})"
        raise "code defect - invalid target: #{t.inspect}" + file_line
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
