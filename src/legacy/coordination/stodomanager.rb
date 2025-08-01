require 'ruby_contracts'
require 'mailer'
require 'calendarentry'
require 'preconditionerror'
require 'targetbuilder'
require 'stodotargeteditor'

# Basic manager of STodoTarget objects - creating, modifying/editing,
# deleting, storing, etc.
class STodoManager
  include ErrorTools, Contracts::DSL

  public

  ###  Access

  attr_reader :configuration, :mailer, :calendar

  # "STodoTarget"s that are currently stored in the database
  attr_reader :existing_targets

  # Object responsible for building and/or updating STodoTarget objects
  attr_accessor :target_builder

  # Does persistent data need updating (has it been changed)?
  attr_accessor :dirty

  ###  Queries

  # All targets for which the passed-in block yields 'true' for the
  # target's handle
  # Array<STodoTarget>
  def selected_targets
    result = existing_targets.values.select do |obj|
      yield obj.handle
    end
    result
  end

  # All handles in the database for which the passed-in block yields 'true'
  # Array<STodoTarget>
  def selected_handles
    result = existing_targets.keys.select do |key|
      yield key
    end
    result
  end

  ###  Element change

  def target_builder=(t)
    @target_builder = t
  end

  ###  Basic operations

  # Process any pending "STodoTarget"s - i.e., those that are specified to
  # be created and/or existing "STodoTarget"s to be edited.
  # Call `initiate' on the resulting new or edited targets and save the
  # results to persistent store.
  pre 'target_builder set' do ! self.target_builder.nil? end
  pre 'targets nil' do target_builder.targets.nil? end
  def perform_initial_processing
    process_targets
    if processing_required then
      initiate_new_targets @new_targets.values
      @edited_targets.values.each do |t|
        if self.target_builder.time_changed_for[t] then
          t.initiate(calendar, self)
        end
      end
      self.target_builder.spec_collector.initial_cleanup @new_targets
      if ! @edited_targets.empty? then
        self.target_builder.spec_collector.initial_cleanup @edited_targets
      end
      save_new_targets
    end
  end

  # Perform any "ongoing processing" (i.e., call
  # STodoTarget#perform_ongoing_processing) required for existing_targets.
  pre 'existing_targets != nil' do self.existing_targets != nil end
  def perform_ongoing_processing
    self.dirty = false
    email = Email.new(mailer)
    changed_items, git_items = [], []
    repo = configuration.stodo_git
    self.existing_targets.values.each do |t|
      t.add_notifier(email)
      self.dirty = false
      # (Pass 'self' to allow t to set 'dirty':)
      t.perform_ongoing_actions(self)
      if dirty then
        changed_items << t
        if repo.in_git t.handle then
          git_items << t
        end
      end
    end
    if ! changed_items.empty? then
      if ! git_items.empty? then
        repo.update_items git_items
        repo.commit "updated #{repo.update_count} items"
      end
      update_database
    end
  end

  # Output a "template" for each element of 'target_builder.targets'.
  pre 'target_builder set' do ! self.target_builder.nil? end
  def output_template
    self.target_builder.existing_targets = self.existing_targets
    if ! target_builder.targets_prepared? then
      target_builder.process_targets
    end
    tgts = target_builder.targets
    if tgts and ! tgts.empty? then
      tgts.each do |t|
        puts t.to_s(true)
      end
      if self.existing_targets then
        cand_parents = self.existing_targets.values.select do |t|
          t.can_have_children?
        end
        if ! cand_parents.empty? then
          print "#candidate-parents: "
          puts (cand_parents.map {|t| t.handle }).join(', ')
        end
      end
      puts "#spec-path: #{Configuration.instance.spec_path}"
    end
  end

  # Perform `command' on the target with handle `handle'.
  pre 'args valid' do |handle, command|
    ! handle.nil? && ! command.nil? && ! handle.empty? && ! command.empty?
  end
  pre 'opts valid' do |h, c, opts| opts.nil? || opts.is_a?(Array) end
  def edit_target(handle, command, options = nil)
    cmdarg = command
    if ! options.nil? then
      cmdarg = [command] + options
    end
    editor.apply_command(handle, cmdarg)
    if editor.last_command_failed then
      $log.error editor.last_failure_message
    else
      if editor.change_occurred then
        update_database
      end
    end
  end

  # Finalize any editing actions begun by 'edit_target'.
  # (For example, run pending git-commit.)
  def close_edit
    editor.close_edit
  end

  # Add the newly-created targets specified by target_builder.targets -
  # to persistent store.
  pre 'target_builder set' do ! target_builder.nil? end
  pre 'tbuilder.existing_targets set' do
    ! self.target_builder.existing_targets.nil?
  end
  def add_new_targets
@logf = File.new("/tmp/add_new_targets", "w")
    target_builder.process_targets
    targets = target_builder.targets
@logf.puts("targets.count: #{targets.count}")
@logf.flush
    if ! targets.empty? then
      targets.each do |t|
@logf.puts("t: #{t}")
@logf.flush
        repo = configuration.stodo_git
        $log.debug "[add_new_targets] adding #{t.handle}"
        store_target(t)
@logf.puts("tried to store target")
@logf.puts("self.inspect: #{self.inspect}")
@logf.flush
        if ! t.parent_handle.nil? then
          p = target_for(t.parent_handle)
          if p then
            p.add_child t
          else
            $log.warn "invalid parent handle (#{t.parent_handle}) for" \
              "item #{t.handle} - changing to 'no-parent'"
              t.parent_handle = nil
          end
        end
        if t.commit then
          repo.update_item(t)
          repo.commit t.commit
        end
      end
      initiate_new_targets targets
      update_database
    end
  end

  # Ensure that the specified targets are updated in persistent store.
  pre 'target_builder set' do ! self.target_builder.nil? end
  def update_targets options
    if ! target_builder.targets_prepared? then
      target_builder.prepare_targets
    end
    target_builder.process_targets
    edits = target_builder.edited_targets
    if ! edits.empty? then
      repo = configuration.stodo_git
      repo.update_items_and_commit(edits, options.commit_message, true)
    end
    update_database
  end

  # Begin a transaction:
  def start_transaction
    translog = configuration.transaction_manager
    if ! translog.in_transaction then
      # Note: $log.* operations should not be invoked before
      # 'translog.start_transaction' is called.
      translog.start_transaction
      $log.warn("[starting transaction - translog: #{translog}]")
    end
  end

  # End a transaction:
  def end_transaction
    translog = configuration.transaction_manager
    $log.warn("[ending transaction - translog: #{translog}]")
    translog.end_transaction
    $log.warn("[ended transaction - translog: #{translog}]")
  end

  private

  ###    Initialization

  post 'existing_targets set' do ! self.existing_targets.nil? end
  post 'configuration set' do !self.configuration.nil? end
  # Note: If Configuration.instance will be called before STodoManager.new,
  # Configuration.service_name and Configuration.debugging need to be set
  # before calling Configuration.instance.
  def initialize(target_builder: nil, service_name: "", debugging: false)
    if Configuration.service_name.nil? then
      # First, set these class attributes in Configuration.
      Configuration.service_name = service_name
      Configuration.debugging = debugging
    end
    # The above Configuration class attributes will be used here (in
    # Configuration.initialize) to set the corresponding singleton
    # attributes):
    @configuration = Configuration.instance
    @data_manager = @configuration.data_manager
    initialize_existing_targets
    @mailer = Mailer.new @configuration
    @calendar = CalendarEntry.new @configuration
    init_new_targets target_builder
  end

  def editor
    if @editor == nil then
      @editor = STodoTargetEditor.new(self.existing_targets)
    end
    @editor
  end

  def initialize_existing_targets
    @existing_targets = @data_manager.restored_targets
  end

  # Set target-related attributes to initial (empty) value
  post 'target_builder set' do |tgt_bldr| self.target_builder == tgt_bldr end
  post 'no targets yet' do
    self.target_builder.nil? || self.target_builder.targets.nil?
  end
  post 'target-related attributes not nil' do
    ! (@new_targets.nil? || @edited_targets.nil?)
  end
  post 'target-related attributes empty' do
    @new_targets.empty? && @edited_targets.empty?
  end
  def init_new_targets tgt_builder
    @new_targets = {}
    @edited_targets = {}
    self.target_builder = tgt_builder
  end

  ###    Implementation

  # Use self.target_builder to process new STodoTargets or edit existing
  # ones (self.existing_targets), depending on current context/state.
  # Insert any new STodoTargets created as a result into the @new_targets
  # hash-table, using the handle as the key.
  # Insert any existing targets that were edited
  # (target_builder.edited_targets) into @edited_targets.
  # Call 'add_child' on each new or edited STodoTarget to ensure that its
  # parent/child relation is up to date.
  pre  'target_builder not nil' do ! self.target_builder.nil? end
  pre  'existing_targets not nil' do ! self.existing_targets.nil? end
  pre  'other target-related attributes not nil' do
    ! (@new_targets.nil? || @edited_targets.nil?)
  end
  pre  'targets not yet processed' do self.target_builder.targets.nil?  end
  post 'targets processed' do ! self.target_builder.targets.nil?  end
  def process_targets
    self.target_builder.existing_targets = self.existing_targets
    self.target_builder.process_targets
    tgts = self.target_builder.targets
    new_duphndles = {}
    tgts.each do |tgt|
      hndl = tgt.handle
      if self.existing_targets[hndl] != nil then
        t = self.existing_targets[hndl]
        $log.debug "Handle #{hndl} already exists."
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
    self.target_builder.edited_targets.each do |tgt|
      @edited_targets[tgt.handle] = tgt
    end
    repo = configuration.stodo_git
    if ! @edited_targets.empty? then
      repo.update_items(@edited_targets.values, true)
      msg = @edited_targets.values.select { |i| i.commit }.map do |i|
        i.commit
      end.join("\n")
      if msg.empty? then
        msg = "updated #{repo.update_count} items"
      end
      repo.commit msg
    end
    if ! @new_targets.empty? then
      @new_targets.values.each do |i|
        msg = i.commit
        if msg then
          repo.update_item(i)
          repo.commit msg
        end
      end
    end
  end

  # Call 'initiate' on each new target in 'targets'.
  def initiate_new_targets targets
    email = Email.new(mailer)
    targets.each do |t|
      t.add_notifier(email)
      t.initiate(calendar, self)
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
  # 'add_child", to the parent's children.
  def add_child(t)
    p, abort_add = t.parent_handle, false
    $log.debug "[add_child] t, p: '#{t.handle}', '#{p}'"
    if p then
      candidate_parent = @new_targets[p]
      if not candidate_parent then
        candidate_parent = target_for(p)
        if candidate_parent then
          $log.debug "#{t.handle}'s parent found among old targets: " +
            "'#{candidate_parent.title}'"
          if candidate_parent.can_have_children? then
            matching_child = candidate_parent.children.find do |c|
              t.handle == c.handle
            end
            if matching_child != nil then
              # t is already a child of candidate_parent:
              abort_add = true
            end
          end
        else
          $log.warn "#{t.handle}'s parent not found."
        end
      else
        $log.debug "#{t.handle}'s parent found among new targets: " +
          "'#{candidate_parent.title}'"
      end
      if candidate_parent then
        if ! abort_add and candidate_parent.can_have_children? then
          $log.debug "[add_child] adding #{t.handle} to " +
            candidate_parent.handle
          candidate_parent.add_child(t)
        else
          if ! abort_add then
            $log.warn "target #{t.handle} is specified with a parent, " +
              "#{p}, that can't have children."
          else
            $log.warn "target #{t.handle} is already a child of #{p}"
          end
          t.parent_handle = nil
        end
      else
        $log.warn "target #{t.handle} has a nonexistent parent: #{p}"
      end
    end
  end

  # Save any new 'STodoTarget's (@new_targets) to the database.
  def save_new_targets
    all_targets = self.existing_targets.merge(@new_targets)
    update_database(all_targets)
  end

  def store_target(tgt)
    self.existing_targets[tgt.handle] = tgt
  end

  def target_for(handle)
    self.existing_targets[handle]
  end

  def update_database(targets = nil)
    if ! targets.nil? then
      @data_manager.store_targets(targets)
    else
      @data_manager.store_targets(self.existing_targets)
    end
  end

end
