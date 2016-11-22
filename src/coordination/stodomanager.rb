require 'mailer'
require 'calendarentry'
require 'preconditionerror'
require 'targetbuilder'
require 'stodotargeteditor'

# Basic manager of s*todo actions
class STodoManager
  include ErrorTools

  attr_reader :existing_targets, :mailer, :calendar

  public

  # Call `initiate' on all new or edited targets.
  def perform_initial_processing
    if processing_required then
      email = Email.new(mailer)
      @new_targets.values.each do |t|
        t.add_notifier(email)
        t.initiate(calendar)
      end
      @edited_targets.values.each do |t|
        if @target_builder.time_changed_for[t] then
          t.initiate(calendar)
        end
      end
      @target_builder.spec_collector.initial_cleanup @new_targets
      if ! @edited_targets.empty? then
        @target_builder.spec_collector.initial_cleanup @edited_targets
      end
      all_targets = existing_targets.merge(@new_targets)
      @data_manager.store_targets(all_targets)
    end
  end

  # Perform any "ongoing processing" required for existing_targets.
  # precondition: existing_targets != nil
  def perform_ongoing_processing
    assert_precondition('existing_targets != nil') { existing_targets != nil }
    email = Email.new(mailer)
    existing_targets.values.each do |t|
      t.add_notifier(email)
$log.warn "calling perform_ongoing_actions on #{t.handle}"
      t.perform_ongoing_actions
    end
$log.warn "[perform_ongoing_actions]HERE"
    # (Calling perform_ongoing_actions above can change a target's state.)
$log.warn "calling @data_manager.store_targets"
    @data_manager.store_targets(existing_targets)
  end

  def output_template target_builder
    tgts = target_builder.targets
    if tgts and ! tgts.empty? then
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

  # Perform `command' on the target with handle `handle'.
  def edit_target(handle, command)
    editor.apply_command(handle, command)
    if editor.last_command_failed then
      $log.error editor.last_failure_message
    else
      @data_manager.store_targets(existing_targets)
    end
  end

  private

  def editor
    if @editor == nil then
      @editor = STodoTargetEditor.new(existing_targets)
    end
    @editor
  end

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
    @edited_targets = {}
    @target_builder = tgt_builder
    @target_builder.build_targets existing_targets
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
    @target_builder.edited_targets.each do |tgt|
      @edited_targets[tgt.handle] = tgt
      add_child(tgt)
    end
  end

  # Have new targets been created or existing targets been edited?
  def processing_required
    (@new_targets != nil and ! @new_targets.empty?) or
    (@edited_targets != nil and ! @edited_targets.empty?)
  end

  def report_new_conflict target1, target2
    msg = "The same handle, #{target1.handle}, was found in 2 or more new " +
      "items: item1: #{target1.title}/#{target1.formal_type}, item2: " +
      "#{target2.title}/#{target2.formal_type}"
    $log.warn msg
  end

  # If 't' has a 'parent_handle', find its parent and add 't', via
  # 'add_task", to the parent's tasks.
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

end
