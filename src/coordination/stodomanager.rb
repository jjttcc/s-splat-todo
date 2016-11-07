require 'mailer'
require 'calendarentry'
require 'preconditionerror'
require 'targetbuilder'

# Basic manager of s*todo actions
class STodoManager
  attr_reader :new_targets, :existing_targets, :mailer, :calendar

  public

  # Call `initiate' on each element of @new_targets.
  # precondition: new_targets != nil
  def perform_initial_processing
    raise PreconditionError, 'new_targets != nil' if new_targets == nil
    email = Email.new(mailer)
    new_targets.values.each do |t|
      t.add_notifier(email)
      t.initiate(self)
    end
    @target_builder.spec_collector.initial_cleanup new_targets
    all_targets = existing_targets.merge(new_targets)
    @data_manager.store_targets(all_targets)
  end

  # Perform any "ongoing processing" required for existing_targets.
  # precondition: existing_targets != nil
  def perform_ongoing_processing
    raise PreconditionError,'existing_targets != nil' if existing_targets == nil
    email = Email.new(mailer)
    existing_targets.values.each do |t|
      t.add_notifier(email)
      t.perform_ongoing_actions(self)
    end
    # (Calling perform_ongoing_actions above can change a target's state.)
    @data_manager.store_targets(existing_targets)
  end

  # List info about all of the specified targets.
  def list_targets targets = existing_targets
    targets.values.each do |t|
      puts target_info(t)
    end
  end

  # Report all descendants (child targets, their children, ...) for each
  # item in `targets'.
  def report_targets_descendants targets = existing_targets
    targets.values.each do |t|
      if t.can_have_children? then
        report_descendants(t)
      end
    end
  end

  def output_template target_builder
    tgts = target_builder.targets
    if tgts then
      tgts.each do |t|
        puts t
      end
      if existing_targets then
        cand_parents = existing_targets.values.select {|t| t.can_have_children?}
        if ! cand_parents.empty? then
          print "#candidate-parents: "
          puts (cand_parents.map {|t| t.handle }).join(', ')
        end
      end
    end
  end

  private

  def initialize config = nil, tgt_builder = nil
    if config != nil then
      @data_manager = config.data_manager
      @existing_targets = @data_manager.restored_targets
      @mailer = Mailer.new config
      @calendar = CalendarEntry.new config
    end
    if tgt_builder != nil then
      init_new_targets tgt_builder
    end
  end

  def init_new_targets tgt_builder
    new_duphndles = {}
    @new_targets = {}
    @target_builder = tgt_builder
    tgts = @target_builder.targets
    tgts.each do |tgt|
      hndl = tgt.handle
      if @existing_targets[hndl] != nil then
        t = @existing_targets[hndl]
        $log.warn "Handle #{hndl} already exists - cannot process the" +
          " associated #{t.formal_type} - skipping this item."
      else
        if @new_targets[hndl] != nil then
          new_duphndles[hndl] = true
          report_new_conflict @new_targets[hndl], tgt
        else
          @new_targets[hndl] = tgt
        end
      end
    end
    # Remove any remaining new targets with a conflicting/duplicate handle.
    new_duphndles.keys.each {|h| @new_targets.delete(h) }
    @new_targets.values.each do |t|
      add_child(t)
    end
  end

  def report_new_conflict target1, target2
    msg = "The same handle, #{target1.handle}, was found in 2 or more new " +
      "items: item1: #{target1.title}/#{target1.formal_type}, item2: " +
      "#{target2.title}/#{target2.formal_type}"
    $log.warn msg
  end

  # If 't' has a parent, find its parent and add 't', via 'add_task", to
  # the parent's tasks.
  def add_child(t)
    p = t.parent_handle
    if p then
      candidate_parent = @new_targets[p]
      if not candidate_parent then
        candidate_parent = @existing_targets[p]
        if candidate_parent then
          $log.debug "#{t.handle}'s parent found among old targets: " +
            "'#{candidate_parent.title}'"
        end
      else
        $log.debug "#{t.handle}'s parent found among new targets: " +
          "'#{candidate_parent.title}'"
      end
      if candidate_parent then
        if candidate_parent.can_have_children? then
          candidate_parent.add_task(t)
        else
          $log.warn "target #{t.handle} is specified with a parent, " +
            "#{p}, that can't have children."
          t.parent_handle = nil
        end
      else
        $log.warn "target #{t.handle} has a nonexistent parent: #{p}"
      end
    end
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
#!!!to-do: include date/time
    result = "[#{t.handle}] #{t.title}; "
    if t.priority then result += "priority: #{t.priority}; " end
    result += "cats: " + t.categories.join(',')
    result += " (#{t.formal_type})"
  end

end
