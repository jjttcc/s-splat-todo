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

  # List the handle for all targets.
  # (!!!!re-spec this method, perhaps!!!!)
  def list_handles(criteria)
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

require 'byebug'
  # List info about the targets with the specified handles and criteria.
  def report_complete criteria
#byebug
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
=begin
    targets_due = targets_for_criteria(criteria).sort.map do |t|
      TargetDue.new(t)
    end

    targets_due = (targets_for(criteria.handles).select do |t|
      t.state == nil or criteria.states.include?(t)
    end).sort.map do |t|
      TargetDue.new(t)
    end
=end
    puts targets_due.join("\n")
  end

  private

  def initialize manager
    self.manager = manager
    create_compare_methods
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
#!!!!!Need to analyze 'criteria' and based on its state, create a pointer
#!!!!!to a method that uses only the priority, only the status, or etc.
    if ! criteria.handles_only? then
      apply_criteria = comparison_method(criteria)
      result = result.select do |t|
        apply_criteria.call(t, criteria)
=begin
        criteria.priorities.include?(t.priority) &&
          (t.state == nil || criteria.states.include?(t))
=end
      end
    end
    result
  end

  def old___targets_for_criteria criteria, sorted = true
    result = targets_for(criteria.handles, sorted)
    if ! criteria.handles_only? then
      result = result.select do |t|
        criteria.priorities.include?(t.priority) &&
          (t.state == nil || criteria.states.include?(t))
      end
    end
    result
  end

  # Create the table of lambdas (comparison_method_table) to use for
  # criteria comparison.
#!!!!!remove:
  def try0_create_compare_methods
    self.comparison_method_table = {}
    self.comparison_method_table[PRI] = lambda { |tgt, crit|
      crit.priorities.include?(tgt.priority)
    }
    self.comparison_method_table[STATE] = lambda { |tgt, crit|
      crit.priorities.include?(tgt.priority)
    }
    self.comparison_method_table[PRI] = lambda { |tgt, crit|
      crit.priorities.include?(tgt.priority)
    }
    self.comparison_method_table[PRI] = lambda { |tgt, crit|
      crit.priorities.include?(tgt.priority)
    }
    self.comparison_method_table[PRI] = lambda { |tgt, crit|
      crit.priorities.include?(tgt.priority)
    }
  end

  # Create the table of lambdas (comparison_method_table) to use for
  # criteria comparison.
  def try1__create_compare_methods
    @comparison_method_table = {}
    pri_cmp = lambda {|t, cr| cr.priorities.include?(t.priority) }
    sta_cmp = lambda {|t, cr| t.state == nil || cr.states.include?(t) }
    ttl_cmp = lambda {|t, cr| cr.title_exprs.any? { |e|
      Regexp.new(e, Regexp::IGNORECASE).match(t.title) }}
    hnd_cmp = lambda {|t, cr| cr.handle_exprs.any? { |e|
      Regexp.new(e, Regexp::IGNORECASE).match(t.handle) }}
    @comparison_method_table[PRI] = pri_cmp
    @comparison_method_table[STATE] = sta_cmp
    @comparison_method_table[TITLE] = ttl_cmp
    @comparison_method_table[HANDLE] = hnd_cmp
    @comparison_method_table[PRI+STATE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+TITLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+TITLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+HANDLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[TITLE+HANDLE] = lambda do |tgt, crit|
      ttl_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+TITLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+TITLE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+TITLE+HANDLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+TITLE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        ttl_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
  end

  # Create the table of lambdas (comparison_method_table) to use for
  # criteria comparison.
  def try2_create_compare_methods
    @comparison_method_table = {}
=begin
    pri_cmp = lambda {|t, cr| cr.priorities.include?(t.priority) }
    sta_cmp = lambda {|t, cr| t.state == nil || cr.states.include?(t) }
    ttl_cmp = lambda {|t, cr| cr.title_exprs.any? { |e|
      Regexp.new(e, Regexp::IGNORECASE).match(t.title) }}
    hnd_cmp = lambda {|t, cr| cr.handle_exprs.any? { |e|
      Regexp.new(e, Regexp::IGNORECASE).match(t.handle) }}
=end
    @comparison_method_table[PRI] = lambda {|t, cr|
      cr.priorities.include?(t.priority) }
    @comparison_method_table[STATE] = lambda {|t, cr|
      t.state == nil || cr.states.include?(t) }
    @comparison_method_table[TITLE] = lambda {|t, cr| cr.title_exprs.any? {|e|
      Regexp.new(e, Regexp::IGNORECASE).match(t.title) }}
    @comparison_method_table[HANDLE] = lambda {|t, cr| cr.handle_exprs.any? {|e|
      Regexp.new(e, Regexp::IGNORECASE).match(t.handle) }}
    @comparison_method_table[DESCRIPTION]
    # 2-element combinations of PRI + <remaining-keys>:
    [STATE, TITLE, HANDLE, DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{PRI}+#{key}"
      @comparison_method_table[PRI+key] = lambda do |tgt, crit|
        @comparison_method_table[PRI].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 2-element combinations of STATE + <remaining-keys>:
    [TITLE, HANDLE, DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{STATE}+#{key}"
      @comparison_method_table[STATE+key] = lambda do |tgt, crit|
        @comparison_method_table[STATE].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 2-element combinations of TITLE + <remaining-keys>:
    [HANDLE, DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{TITLE}+#{key}"
      @comparison_method_table[TITLE+key] = lambda do |tgt, crit|
        @comparison_method_table[TITLE].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 2-element combinations of HANDLE + <remaining-keys>:
    [DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{HANDLE}+#{key}"
      @comparison_method_table[HANDLE+key] = lambda do |tgt, crit|
        @comparison_method_table[HANDLE].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 3-element combinations of PRI + <remaining-keys1> + <remaining-keys2>:
    [STATE, TITLE, HANDLE, DESCRIPTION].each do |key1|
      [TITLE, HANDLE, DESCRIPTION].each do |key2|
$stderr.puts "adding cmethod for #{PRI}+#{key1}+#{key2}"
        @comparison_method_table[HANDLE+key] = lambda do |tgt, crit|
          @comparison_method_table[HANDLE].call(tgt, crit) &&
            @comparison_method_table[key].call(tgt, crit)
        end
      end
    end
=begin
    @comparison_method_table[PRI+STATE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+TITLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+TITLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+HANDLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[TITLE+HANDLE] = lambda do |tgt, crit|
      ttl_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+TITLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+TITLE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+TITLE+HANDLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+TITLE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        ttl_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
=end
  end

  # Create the table of lambdas (comparison_method_table) to use for
  # criteria comparison.
  def try3__create_compare_methods
    @comparison_method_table = {}
    pri_cmp = lambda {|tgt, crit|
      crit.priorities.include?(tgt.priority)
    }
    sta_cmp = lambda {|tgt, crit|
      tgt.state == nil || crit.states.include?(tgt)
    }
    ttl_cmp = lambda {|tgt, crit|
      crit.title_exprs.any? { |e|
      Regexp.new(e, Regexp::IGNORECASE).match(tgt.title) }
    }
    hnd_cmp = lambda {|tgt, crit|
      crit.handle_exprs.any? { |e|
      Regexp.new(e, Regexp::IGNORECASE).match(tgt.handle) }
    }

    @comparison_method_table[PRI] = pri_cmp
    @comparison_method_table[STATE] = sta_cmp
    @comparison_method_table[TITLE] = ttl_cmp
    @comparison_method_table[HANDLE] = hnd_cmp

    [PRI, STATE, TITLE, HANDLE].each do |k|
      [STATE, TITLE, HANDLE].each do |l|
        if l == k then
          # Prevent key duplications.
          break
        end
        # 2-element combinations of k + <remaining-keys>:
        @comparison_method_table[k+l] = lambda {|tgt, crit|
$stderr.puts "adding cmethod for #{k}+#{l}"
          @comparison_method_table[k].call(tgt, crit) &&
            @comparison_method_table[l].call(tgt, crit)
        }
        [TITLE, HANDLE].each do |m|
          if m == l || m == k then
            # Prevent key duplications.
            break
          end
          # 3-element combinations of k + <remaining-keys>:
          @comparison_method_table[k+l+m] = lambda {|tgt, crit|
$stderr.puts "adding cmethod for #{k}+#{l}+#{m}"
            @comparison_method_table[k].call(tgt, crit) &&
              @comparison_method_table[l].call(tgt, crit) &&
              @comparison_method_table[m].call(tgt, crit)
          }
          [HANDLE].each do |n|
            if n == m || n == l || n == k then
              # Prevent key duplications.
              break
            end
            # 3-element combinations of k + <remaining-keys>:
            @comparison_method_table[k+l+m+n] = lambda {|tgt, crit|
$stderr.puts "adding cmethod for #{k}+#{l}+#{m}+#{n}"
              @comparison_method_table[k].call(tgt, crit) &&
                @comparison_method_table[l].call(tgt, crit) &&
                @comparison_method_table[m].call(tgt, crit) &&
                @comparison_method_table[n].call(tgt, crit)
            }
          end
        end
      end
    end
$stderr.puts "cmtbl.count: #{@comparison_method_table.count}"
@comparison_method_table.each_key do |k|
  $stderr.puts "cmtbl[#{k}]: #{@comparison_method_table[k]}"
end
exit(0)

=begin
    @comparison_method_table[PRI] = lambda {|t, cr|
      cr.priorities.include?(t.priority) }
    @comparison_method_table[STATE] = lambda {|t, cr|
      t.state == nil || cr.states.include?(t) }
    @comparison_method_table[TITLE] = lambda {|t, cr| cr.title_exprs.any? {|e|
      Regexp.new(e, Regexp::IGNORECASE).match(t.title) }}
    @comparison_method_table[HANDLE] = lambda {|t, cr| cr.handle_exprs.any? {|e|
      Regexp.new(e, Regexp::IGNORECASE).match(t.handle) }}
    @comparison_method_table[DESCRIPTION]
    # 2-element combinations of PRI + <remaining-keys>:
    [STATE, TITLE, HANDLE, DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{PRI}+#{key}"
      @comparison_method_table[PRI+key] = lambda do |tgt, crit|
        @comparison_method_table[PRI].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 2-element combinations of STATE + <remaining-keys>:
    [TITLE, HANDLE, DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{STATE}+#{key}"
      @comparison_method_table[STATE+key] = lambda do |tgt, crit|
        @comparison_method_table[STATE].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 2-element combinations of TITLE + <remaining-keys>:
    [HANDLE, DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{TITLE}+#{key}"
      @comparison_method_table[TITLE+key] = lambda do |tgt, crit|
        @comparison_method_table[TITLE].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 2-element combinations of HANDLE + <remaining-keys>:
    [DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{HANDLE}+#{key}"
      @comparison_method_table[HANDLE+key] = lambda do |tgt, crit|
        @comparison_method_table[HANDLE].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 3-element combinations of PRI + <remaining-keys1> + <remaining-keys2>:
    [STATE, TITLE, HANDLE, DESCRIPTION].each do |key1|
      [TITLE, HANDLE, DESCRIPTION].each do |key2|
$stderr.puts "adding cmethod for #{PRI}+#{key1}+#{key2}"
        @comparison_method_table[HANDLE+key] = lambda do |tgt, crit|
          @comparison_method_table[HANDLE].call(tgt, crit) &&
            @comparison_method_table[key].call(tgt, crit)
        end
      end
    end
=end
=begin
    @comparison_method_table[PRI+STATE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+TITLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+TITLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+HANDLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[TITLE+HANDLE] = lambda do |tgt, crit|
      ttl_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+TITLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+TITLE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+TITLE+HANDLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+TITLE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        ttl_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
=end
  end

  # Create the table of lambdas (comparison_method_table) to use for
  # criteria comparison.
  def try4__create_compare_methods
    @comparison_method_table = {}
    pri_cmp = lambda {|tgt, crit|
      crit.priorities.include?(tgt.priority)
    }
    sta_cmp = lambda {|tgt, crit|
      tgt.state == nil || crit.states.include?(tgt)
    }
    ttl_cmp = lambda {|tgt, crit|
      crit.title_exprs.any? { |e|
      Regexp.new(e, Regexp::IGNORECASE).match(tgt.title) }
    }
    hnd_cmp = lambda {|tgt, crit|
      crit.handle_exprs.any? { |e|
      Regexp.new(e, Regexp::IGNORECASE).match(tgt.handle) }
    }

    @comparison_method_table[PRI] = pri_cmp
    @comparison_method_table[STATE] = sta_cmp
    @comparison_method_table[TITLE] = ttl_cmp
    @comparison_method_table[HANDLE] = hnd_cmp

    [PRI, STATE, TITLE, HANDLE].each do |k|
      [STATE, TITLE, HANDLE].each do |l|
        if l == k then
          # Prevent key duplications.
          break
        end
        [TITLE, HANDLE].each do |m|
          if m == l || m == k then
            # Prevent key duplications.
            break
          end
          [HANDLE].each do |n|
            if n == m || n == l || n == k then
              # Prevent key duplications.
              break
            end
            # 4-element combinations of k + <remaining-keys>:
            mtbl_key = standardized_key_combo([k, l, m, n])
$stderr.puts "adding cmethod for #{mtbl_key}"
            @comparison_method_table[mtbl_key] = lambda {|tgt, crit|
              @comparison_method_table[k].call(tgt, crit) &&
                @comparison_method_table[l].call(tgt, crit) &&
                @comparison_method_table[m].call(tgt, crit) &&
                @comparison_method_table[n].call(tgt, crit)
            }
          end
          # 3-element combinations of k + <remaining-keys>:
          mtbl_key = standardized_key_combo([k, l, m])
$stderr.puts "adding cmethod for #{mtbl_key}"
          @comparison_method_table[mtbl_key] = lambda {|tgt, crit|
            @comparison_method_table[k].call(tgt, crit) &&
              @comparison_method_table[l].call(tgt, crit) &&
              @comparison_method_table[m].call(tgt, crit)
          }
        end
        # 2-element combinations of k + <remaining-keys>:
        mtbl_key = standardized_key_combo([k, l])
$stderr.puts "adding cmethod for #{mtbl_key}"
        @comparison_method_table[mtbl_key] = lambda {|tgt, crit|
          @comparison_method_table[k].call(tgt, crit) &&
            @comparison_method_table[l].call(tgt, crit)
        }
      end
    end
$stderr.puts "[old-not-current]cmtbl.count: #{@comparison_method_table.count}"
@comparison_method_table.each_key do |k|
  $stderr.puts "cmtbl[#{k}]: #{@comparison_method_table[k]}"
end
#!!!!exit(0)

=begin
    @comparison_method_table[PRI] = lambda {|t, cr|
      cr.priorities.include?(t.priority) }
    @comparison_method_table[STATE] = lambda {|t, cr|
      t.state == nil || cr.states.include?(t) }
    @comparison_method_table[TITLE] = lambda {|t, cr| cr.title_exprs.any? {|e|
      Regexp.new(e, Regexp::IGNORECASE).match(t.title) }}
    @comparison_method_table[HANDLE] = lambda {|t, cr| cr.handle_exprs.any? {|e|
      Regexp.new(e, Regexp::IGNORECASE).match(t.handle) }}
    @comparison_method_table[DESCRIPTION]
    # 2-element combinations of PRI + <remaining-keys>:
    [STATE, TITLE, HANDLE, DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{PRI}+#{key}"
      @comparison_method_table[PRI+key] = lambda do |tgt, crit|
        @comparison_method_table[PRI].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 2-element combinations of STATE + <remaining-keys>:
    [TITLE, HANDLE, DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{STATE}+#{key}"
      @comparison_method_table[STATE+key] = lambda do |tgt, crit|
        @comparison_method_table[STATE].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 2-element combinations of TITLE + <remaining-keys>:
    [HANDLE, DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{TITLE}+#{key}"
      @comparison_method_table[TITLE+key] = lambda do |tgt, crit|
        @comparison_method_table[TITLE].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 2-element combinations of HANDLE + <remaining-keys>:
    [DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{HANDLE}+#{key}"
      @comparison_method_table[HANDLE+key] = lambda do |tgt, crit|
        @comparison_method_table[HANDLE].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 3-element combinations of PRI + <remaining-keys1> + <remaining-keys2>:
    [STATE, TITLE, HANDLE, DESCRIPTION].each do |key1|
      [TITLE, HANDLE, DESCRIPTION].each do |key2|
$stderr.puts "adding cmethod for #{PRI}+#{key1}+#{key2}"
        @comparison_method_table[HANDLE+key] = lambda do |tgt, crit|
          @comparison_method_table[HANDLE].call(tgt, crit) &&
            @comparison_method_table[key].call(tgt, crit)
        end
      end
    end
=end
=begin
    @comparison_method_table[PRI+STATE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+TITLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+TITLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+HANDLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[TITLE+HANDLE] = lambda do |tgt, crit|
      ttl_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+TITLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+TITLE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+TITLE+HANDLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+TITLE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        ttl_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
=end
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
    @comparison_method_table[TITLE] = ttl_cmp
    @comparison_method_table[HANDLE] = hnd_cmp
    @comparison_method_table[DESCRIPTION] = des_cmp

#!!!!rm: [STATE, TITLE, HANDLE, DESCRIPTION].each do |key|
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
$stderr.puts "adding cmethod for #{mtbl_key}"
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
$stderr.puts "adding cmethod for #{mtbl_key}"
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
$stderr.puts "adding cmethod for #{mtbl_key}"
          @comparison_method_table[mtbl_key] = lambda {|tgt, crit|
            @comparison_method_table[k].call(tgt, crit) &&
              @comparison_method_table[l].call(tgt, crit) &&
              @comparison_method_table[m].call(tgt, crit)
          }
        end
        # 2-element combinations of k + <remaining-keys>:
        mtbl_key = standardized_key_combo([k, l])
$stderr.puts "adding cmethod for #{mtbl_key}"
        @comparison_method_table[mtbl_key] = lambda {|tgt, crit|
          @comparison_method_table[k].call(tgt, crit) &&
            @comparison_method_table[l].call(tgt, crit)
        }
      end
    end
$stderr.puts "[current]cmtbl.count: #{@comparison_method_table.count}"
@comparison_method_table.each_key do |k|
  $stderr.puts "cmtbl[#{k}]: #{@comparison_method_table[k]}"
end
#!!!!exit(0)

=begin
    @comparison_method_table[PRI] = lambda {|t, cr|
      cr.priorities.include?(t.priority) }
    @comparison_method_table[STATE] = lambda {|t, cr|
      t.state == nil || cr.states.include?(t) }
    @comparison_method_table[TITLE] = lambda {|t, cr| cr.title_exprs.any? {|e|
      Regexp.new(e, Regexp::IGNORECASE).match(t.title) }}
    @comparison_method_table[HANDLE] = lambda {|t, cr| cr.handle_exprs.any? {|e|
      Regexp.new(e, Regexp::IGNORECASE).match(t.handle) }}
    @comparison_method_table[DESCRIPTION]
    # 2-element combinations of PRI + <remaining-keys>:
    [STATE, TITLE, HANDLE, DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{PRI}+#{key}"
      @comparison_method_table[PRI+key] = lambda do |tgt, crit|
        @comparison_method_table[PRI].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 2-element combinations of STATE + <remaining-keys>:
    [TITLE, HANDLE, DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{STATE}+#{key}"
      @comparison_method_table[STATE+key] = lambda do |tgt, crit|
        @comparison_method_table[STATE].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 2-element combinations of TITLE + <remaining-keys>:
    [HANDLE, DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{TITLE}+#{key}"
      @comparison_method_table[TITLE+key] = lambda do |tgt, crit|
        @comparison_method_table[TITLE].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 2-element combinations of HANDLE + <remaining-keys>:
    [DESCRIPTION].each do |key|
$stderr.puts "adding cmethod for #{HANDLE}+#{key}"
      @comparison_method_table[HANDLE+key] = lambda do |tgt, crit|
        @comparison_method_table[HANDLE].call(tgt, crit) &&
          @comparison_method_table[key].call(tgt, crit)
      end
    end
    # 3-element combinations of PRI + <remaining-keys1> + <remaining-keys2>:
    [STATE, TITLE, HANDLE, DESCRIPTION].each do |key1|
      [TITLE, HANDLE, DESCRIPTION].each do |key2|
$stderr.puts "adding cmethod for #{PRI}+#{key1}+#{key2}"
        @comparison_method_table[HANDLE+key] = lambda do |tgt, crit|
          @comparison_method_table[HANDLE].call(tgt, crit) &&
            @comparison_method_table[key].call(tgt, crit)
        end
      end
    end
=end
=begin
    @comparison_method_table[PRI+STATE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+TITLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+TITLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+HANDLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[TITLE+HANDLE] = lambda do |tgt, crit|
      ttl_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+TITLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        ttl_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+TITLE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[STATE+TITLE+HANDLE] = lambda do |tgt, crit|
      sta_cmp.call(tgt, crit) && ttl_cmp.call(tgt, crit) &&
        hnd_cmp.call(tgt, crit)
    end
    @comparison_method_table[PRI+STATE+TITLE+HANDLE] = lambda do |tgt, crit|
      pri_cmp.call(tgt, crit) && sta_cmp.call(tgt, crit) &&
        ttl_cmp.call(tgt, crit) && hnd_cmp.call(tgt, crit)
    end
=end
  end

  # "type-spec" keys
  PRI, STATE, TITLE, HANDLE, DESCRIPTION = 'pri', 'state', 'title', 'handle',
    'description'

  attr_reader :comparison_method_table

  def comparison_method(criteria)
    pri_key, stat_key, ttl_key, hndl_key, des_key = '', '', '', '', ''
    if criteria.has_priorities? then
      pri_key = PRI
    end
    if criteria.has_states? then
      stat_key = STATE
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
$stderr.puts "cm - std key combo: #{key}"
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
