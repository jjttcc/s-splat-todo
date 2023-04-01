require 'ruby_contracts'
require 'time'
require 'set'
require 'email'
require 'onetimereminder'
require 'spectools'
require 'timetools'
require 'treenode'
require 'targetstate'
require 'attachment'
require 'dateparser'
require 'targetstatevalues'
require 'periodicdateparser'

# Items - actions, projects, appointments, etc. - to keep track of, not
# forget about, and/or complete
class STodoTarget
  include SpecTools, ErrorTools, TimeTools, TargetStateValues
  include Contracts::DSL

  public

  attr_reader :title, :content, :handle, :calendar_ids, :priority, :comment,
    :reminders, :categories, :parent_handle, :notifiers, :children, :state,
    :last_removed_descendant
  # Array of attached media files:
  attr_reader :attachments
  # Array of STodoTarget references (via handle):
  attr_reader :references
  alias :description :content
  alias :name :handle
  alias :detail :comment
  attr_reader :notification_subject, :full_notification_message,
    :notification_email_addrs, :short_notification_message

  attr_writer :parent_handle
  attr_writer :handle         # Needed for cloning

  public    ###  Access

  def type
    self.class.to_s.downcase
  end

  def time
    raise "<time>: descendant class-method implementation required"
  end

  # "final" reminder - e.g., based on expiration date or due date
  def final_reminder
    nil
  end

  # self's fields, labeled with associated tags, for use as a template in a
  # specification file
  def to_s(template = false)
    result = "#{TYPE_KEY}: #{spec_type}\n"
    if template then
      # 'type: template' in the spec file indicates that the file should be
      # ignored by 'stodo init'; the user must remove the line for the file
      # to be processed - i.e., used to create a new STodoTarget.
      result += "# NOTE: Remove the 'type:' line, below, to allow " +
        "this spec to be processed.\n"
      result += "#{TYPE_KEY}: #{TEMPLATE_TYPE}\n"
    end
    for tag in [TITLE_KEY, HANDLE_KEY, DESCRIPTION_KEY, PRIORITY_KEY,
                COMMENT_KEY, PARENT_KEY] do
      v = self.instance_variable_get("@#{tag}")
      if v == nil then  # (description is an alias, not an attribute.)
        case tag
        when DESCRIPTION_KEY
          if ! template then
            result += "status: #{state}\n"
          end
          v = self.description
        when PARENT_KEY
          v = self.parent_handle
        else
          v = ""
        end
      end
      result += "#{tag}: #{v}\n"
    end
    result += "#{REMINDER_KEY}: "
    remlist = reminders.map do |r|
      r
    end
    result += remlist.join('; ') + "\n"
    result += email_info(template)
    result += "#{CALENDAR_IDS_KEY}: #{calendar_ids.join(', ')}\n"
    result += "#{CATEGORIES_KEY}: #{categories.join(', ')}\n"
    if self.attachments then
      result += "#{ATTACHMENTS_KEY}: #{self.attachments.join(", ")}\n"
    end
    if self.references then
      result += "#{REFERENCES_KEY}: #{self.references.join(", ")}\n"
    end
    result + to_s_appendix
  end

  # All 'reminders' that are in the future
  def upcoming_reminders(sorted = false)
    assert_invariant {invariant}
    now = Time.now
    result = reminders.select do |r|
      r.time > now
    end
    if sorted then
      result.sort!
    end
    result
  end

  # All descendants (children, grandchildren, etc.) of self, if any
  post 'valid result' do |result|
    ! result.nil? && implies(! self.can_have_children?, result.empty?)
  end
  def descendants
    result = []
    children.each do |t|
      result << t
      if t.can_have_children? then
        result.concat(t.descendants)
      end
    end
    result
  end

  # date and time self was completed or canceled
  post '"in-progress or suspended" implies result.nil?' do |result|
    implies(state.value == IN_PROGRESS || state.value == SUSPENDED, result.nil?)
  end
  def completion_date
    result = state.completion_time
    result
  end

  # The descendant with handle 'handle' - nil if no such descendant
  pre '! handle.nil?' do |handle| ! handle.nil?  end
  def descendant handle
    result = children.find do |o| o.handle == handle end
    if result.nil? then
      children.each do |c|
        result = c.descendant handle
        if ! result.nil? then
          # (found it.)
          break
        end
      end
    end
    result
  end

  # All 'children', c, for which c.parent_handle != self.handle
  post 'result is an Array' do |result| result.is_a?(Array) end
  def emancipated_children
    result = self.children.select do |c|
      c.parent_handle != self.handle
    end
    result
  end

  # All "emancipated" 'descendants'
  post 'result is an Array' do |result| result.is_a?(Array) end
  def emancipated_descendants
    result = self.emancipated_children
    self.children.each do |c|
      result.concat(c.emancipated_children)
    end
    result
  end

  public    ###  Comparison

  VERY_LATE = Time.parse('10000-01-01 00:00')

  def <=>(other)
    other_time = other.time != nil ? other.time : VERY_LATE
    mytime = time != nil ? time : VERY_LATE
    result = mytime <=> other_time
    result
  end

  public    ###  Status report

  # Did the last invocation of a method that can change this object's
  # state, and is documented as updating this query, acutally change the
  # state of 'self'?
  attr_reader :last_op_changed_state

  # Is self in an active state?
  def active?
    result = (state == nil) || state.active?
  end

  def can_have_children?
    true
  end

  def spec_type
    raise "<spec_type>: descendant class-method implementation required"
  end

  def formal_type
    self.class
  end

  # Is 'self' valid - i.e., are the field values all valid?
  def valid?
    @valid
  end

  # Does 'self' have a parent?
  def has_parent?
    self.parent_handle != nil
  end

  # Has 'self' been completed?
  def completed?
    result = state.value == COMPLETED
  end

  # Is self a parent of 'target'?
  def is_parent? target
    self.children.include?(target)
  end

  # Is self a child of 'target'?
  def is_child? target
    ! target.nil? && target.children.include?(self)
  end

  public    ###  Element change

  # Add a STodoTarget object to 'children'.
  pre 't != nil and t.parent_handle == handle' do |t|
    ! t.nil? && t.parent_handle == handle
  end
  def add_child(t)
    @children << t
  end

  # Add a notifier to the list of notifiers to be used by `initiate' and
  # `perform_ongoing_actions'.
  # postcondition: notifiers.length == old notifiers.length + 1
  pre 'n != nil' do |n| n != nil end
  def add_notifier n
    @notifiers << n
  end

  # Set self's fields from the non-nil fields in spec.
  pre 'valid_spec' do |spec| ! spec.nil? && self.handle == spec.handle end
  pre 'target_list valid' do |spec, target_list|
    ! target_list.nil? && target_list.is_a?(Hash)
  end
  def modify_fields spec, target_list
    main_modify_fields spec, target_list
    post_modify_fields spec
  end

  # Ensure that 'last_removed_descendant' is not set - i.e., is nil
  def clear_last_removed_descendant
    self.last_removed_descendant = nil
  end

  # Change self's handle to 'h'.
  # If self.children.count > 0, set each child's parent_handle to 'h', the
  # new handle.
  pre 'h exists' do |h| ! h.nil? && h.length > 0 end
  pre 'h != old handle' do |h| h != self.handle end
  post 'handle == h' do |result, h| self.handle == h end
  def change_handle h
    self.handle = h
    self.children.each do |c|
      c.parent_handle = self.handle
    end
  end

  public    ###  Removal

  # Remove child `t' from 'children'.
  def remove_child t
    @children.delete(t)
  end

  # Remove all of self's 'descendants' except for those indicated by
  # 'exceptions'.
  def remove_descendants(exceptions)
    new_childlist = []  # List of children to restore after clear
    # Recursively remove descendants first.
    @children.each do |c|
      c.remove_descendants(exceptions)
    end
    if exceptions != nil && ! exceptions.empty? then
      new_childlist = @children.select do |c|
        # Mark 'c' for restoration if it is in the exceptions list or
        # if its children have not all been cleared (which means that at
        # least one of c's descendants is in the exceptions list):
        exceptions.include?(c.handle) || c.children.count > 0
      end
    end
    @children.clear
    if ! new_childlist.empty? then
      @children = new_childlist
    end
  end

  # Search among 'descendants' to find the descendant with 'handle'. If it
  # is found, remove it as a descendant (which includes adjustments to
  # 'parent' and 'child' relationships to reflect this removal).
  # The query 'last_removed_descendant' will reference the newly found and
  # removed descendant; if the descendant is not found, the result of this
  # query will be nil.
  pre '! handle.nil?' do |handle| ! handle.nil?  end
  def remove_descendant handle
    child = children.find do |o| o.handle == handle end
    if child.nil? then
      children.each do |c|
        c.remove_descendant handle
        if ! c.last_removed_descendant.nil? then
          # (found it.)
          self.last_removed_descendant = c.last_removed_descendant
          break
        end
      end
    else
      detach child
      self.last_removed_descendant = child
    end
  end

  public    ###  Duplication

  # Called by 'dup':
  # Ensure no 'children' and that 'children' and the other complex object
  # attributes ('reminders', 'categories', etc.) do not have the same
  # object_id as the equivalent attribute in orig.
  def initialize_copy(orig)
    super(orig)
    ieas = @initial_email_addrs
    oeas = @ongoing_email_addrs
    @children = Set.new
    @calendar_ids = []
    @initial_email_addrs = []
    @ongoing_email_addrs = []
    @reminders = []
    @categories = []
    @notifiers = []
    # Copy the objects contained in these enumerables - not the references.
    orig.calendar_ids.each do |o|
      @calendar_ids << o.dup
    end
    ieas.each do |o|
      @initial_email_addrs << o.dup
    end
    oeas.each do |o|
      @ongoing_email_addrs << o.dup
    end
    orig.reminders.each do |o|
      @reminders << o.dup
    end
    orig.categories.each do |o|
      @categories << o.dup
    end
    orig.attachments.each do |o|
      @attachments << o.dup
    end
    orig.references.each do |o|
      @references << o.dup
    end
    orig.notifiers.each do |o|
      @notifiers << o.dup
    end
  end

  public    ###  Hash-related queries

  # hash to allow use in a hashtable (Hash)
  def hash
    result = 0
    if self.handle != nil then
      result = self.handle.hash
    end
    result
  end

  # equality operator to allow use in a hashtable (Hash)
  def eql? object
    self.handle == object.handle
  end

  public    ###  Basic operations

  # Perform required initial notifications and related actions.
  def initiate calendar, client
    send_initial_notifications(client)
    set_initial_calendar_entry calendar
  end

  # Perform post-"initiate" notifications.
  def perform_ongoing_actions(client = nil)
    if state.value == IN_PROGRESS then
      send_ongoing_notifications(client)
    end
  end

  # Adopt all of self's descendants that are "emancipated" - i.e., for each
  # descendant, d, of 'self', if d.parent_handle is nil or has a value other
  # than that of the "parent", p, (who claims the descendant as its child)
  # set d's parent_handle to p.handle.
  # If any "emancipated" descendants were found and updated, set
  # last_op_changed_state to true; otherwise, it is set to false.
  def adopt_descendants
    self.last_op_changed_state = false
    self.children.each do |c|
      if c.parent_handle != self.handle then
        c.parent_handle = self.handle
        self.last_op_changed_state = true
      end
      c.adopt_descendants
      if ! last_op_changed_state then
        self.last_op_changed_state = c.last_op_changed_state
      end
    end
  end

  # For each child, c, of 'self' if c.parent_handle is either blank or is the
  # handle of a target other than self, remove c as one of self's children.
  # If 'recursive', perform this same operation recursively on all of self's
  # children.
  def remove_false_children recursive = false
    self.last_op_changed_state = false
    self.children.each do |c|
      if c.parent_handle != self.handle then
        self.remove_child(c)
        self.last_op_changed_state = true
      end
      if recursive then
        c.remove_false_children(recursive)
        if ! last_op_changed_state then
          self.last_op_changed_state = c.last_op_changed_state
        end
      end
    end
  end

  public    ###  Miscellaneous

  def descendants_report
    tree = TreeNode.new(self)
    tree.descendants_report do |t|
      "#{t.handle}, due: #{time_24hour(t.time)}"
    end
  end

  pre '"editing" eixsts' do |editing| ! editing.nil? end
  def process_attachments editing
    if self.attachments then
      self.attachments.each do |a|
        a.process editing
      end
    end
  end

  public    ###  Persistence

  # Make any needed changes before the persistent attributes are saved.
  def prepare_for_db_write
    @notifiers = []
    @email_spec = ""
    @notification_subject = ""
    @full_notification_message = ""
    @notification_email_addrs = nil
    @short_notification_message = ""
    @reminders.each do |r|
      r.prepare_for_db_write
    end
  end

  private

  ###  Assignment (<attribute>= methods)

  attr_writer   :last_removed_descendant
  attr_writer   :last_op_changed_state
  attr_writer   :title, :content, :priority, :comment, :reminders,
    :categories, :state, :attachments, :references
  attr_accessor :email_spec

  private

  ###  Initialization

  post 'invariant' do invariant end
  def initialize spec
    @valid = true
    # Extra database field/object to allow future expansion
    @additional_database_field = nil
    set_fields spec
    check_fields
    set_email_addrs
    @notifiers = []
    @state = TargetState.new
    @reminders = []
    self.last_op_changed_state = false
    if spec.is_template? || time != nil then
      # Build @reminders last because it depends on 'time' (which is an
      # attribute in descendant classes) being set/non-nil.
      rem = reminders_from_spec spec
      if rem then
        @reminders = rem
      end
    else
      rems = spec.reminders
      if rems != nil && ! rems.empty? then
        $log.warn "No date specified for #{spec.handle} - reminders will " +
          "be ignored (#{rems})"
      end
    end
  end

  def set_fields spec
    @children = Set.new
    @title = spec.title
    @handle = spec.handle
    @email_spec = spec.email
    @content = spec.description
    @comment = spec.comment
    @priority = spec.priority
    @categories = []
    @attachments = []
    @references = []
    assign_categories spec
    assign_attachments spec
    assign_references spec
    @calendar_ids = []
    if spec.calendar_ids != nil then
      @calendar_ids = spec.calendar_ids.split(SPEC_FIELD_DELIMITER)
      $log.debug "calendar_ids set: #{calendar_ids}"
    end
    if spec.parent != nil then
      self.parent_handle = spec.parent
    end
  end

  # Update any of self's fields according to 'spec'. Any fields in 'spec'
  # that are nil will be ignored - that is, a nil field is taken to imply
  # that that particular field is not to be changed.
  # If spec.parent == "" (i.e., an empty string), self is changed to become
  # a parent-less top-level ancestor.
  # If self.parent_handle is changed as a result of 'spec', self's old
  # parent (target_list[self.parent_handle]) is updated to not contain self
  # as one of its children; and self's new parent (target_list[spec.parent])
  # is updated to be self's parent - i.e., one of its children.
  # NOTE: If self.parent_handle is changed to a non-empty string, but
  # target_list[spec.parent] does not exist (i.e., spec.parent is bogus),
  # an exception will be thrown and the caller should abort the operation.
  # postcondition: implies(! spec.parent.nil? && spec.parent.length > 0,
  #    self.parent_handle == spec.parent && self.parent_handle ==
  #    target_list[self.parent_handle].handle)
  pre '"spec" is valid' do |spec, target_list|
      ! spec.nil? && self.handle == spec.handle
  end
  pre 'target_list is valid' do |spec, target_list|
      ! target_list.nil? && target_list.is_a?(Hash)
  end
  post 'parent nil if empty spec' do |result, spec, target_list|
    implies(spec.parent == "", self.parent_handle.nil?)
  end
  def main_modify_fields spec, target_list
    guarded_scalar_assignment(:title, spec, nil)
    guarded_scalar_assignment(:content, spec, :description)
    guarded_scalar_assignment(:comment, spec)
    guarded_scalar_assignment(:priority, spec)
    if spec.email then
      guarded_scalar_assignment(:email_spec, spec, :email)
      set_email_addrs
    end
    assign_parent spec.parent, target_list
    if spec.calendar_ids then
      @calendar_ids = spec.calendar_ids.split(SPEC_FIELD_DELIMITER)
    end
    assign_categories spec
    assign_attachments spec
    assign_references spec
  end

  def post_modify_fields spec
    rem = reminders_from_spec spec
    if rem then
      @reminders = rem
    end
  end

  # "Reminder"s created based on spec.reminders - If spec.type == CORRECTION
  # and spec.reminders is nil, nil is returned to indicate that no
  # reminders were specified (i.e., the original reminders should be kept).
  pre 'not spec.is_template? implies time != nil' do |spec|
      implies(! spec.is_template?, time != nil)
  end
  def reminders_from_spec spec
    reminders_string = spec.reminders
    result = []
    if reminders_string != nil then
      begin
        date_strings = reminders_string.split(REMINDER_DELIMITER)
        date_parser = DateParser.new(date_strings, true)
        dates = date_parser.result
        periodic_reminder_candidates = []
        for i in 0 .. dates.length - 1 do
          d = dates[i]
          if d != nil then
            result << OneTimeReminder.new(d)
          else
            if date_strings[i].downcase != NONE then
              periodic_reminder_candidates << date_strings[i]
            end
          end
        end
        if periodic_reminder_candidates.length > 0 then
          periodic_date_parser = PeriodicDateParser.new(
            periodic_reminder_candidates, time)
          periodic_reminders = periodic_date_parser.result
          result.concat(periodic_reminders)
        end
      rescue Exception => e
        $log.warn "#{handle}: #{e} [stack trace:\n" +
          e.backtrace.join("\n") + ']'
        @valid = spec.is_template?  # (> 0 bad reminders makes 'self' invalid.)
      end
    else
      if spec.type == CORRECTION then
        result = nil
      end
    end
    if result then
      result.sort
    end
    result
  end

  ###  Initialization/modification utilities

  # Assign categories from 'spec' to self.categories.
  def assign_categories spec
    if spec.categories then
      @categories = spec.categories.split(SPEC_FIELD_DELIMITER)
    end
  end

  # For each path, p, in 'spec.attachments' (a list of paths), create an
  # Attachment object whose path is p.
  # If 'append', append each new attachment to self.attachments; otherwise,
  # replace self.attachments with a new list created from the paths in
  # 'spec.attachments'.
  # Note: The attachments are processed in the order in which they occur in
  # 'spec.attachments'.  If a particular attachment, 'att', holds the path
  # of a directory, that path is used - for any 
  pre '"attachments" exists' do
    ! self.attachments.nil? && self.attachments.is_a?(Array)
  end
  post '"attachments" still exists' do ! self.attachments.nil? end
  def assign_attachments spec, append = false
    new_attchmts = []
    last_attachment_path = nil
    if spec.attachments then
      spec.attachments.split(SPEC_FIELD_DELIMITER).each do |a|
        if a.empty? then
          $log.warn "empty attachment (in #{spec.attachment})"
        else
          attchmt = Attachment.new a, last_attachment_path
          if attchmt.is_directory? then
            # (I.e., attchmt.path is to be used as the last candidate path
            # for the remaining attachments specified in 'spec'.)
            last_attachment_path = attchmt.path
          end
          if ! attchmt.is_valid? then
            $log.warn "#{attchmt.invalidity_reason}"
            if ! spec.reject_nonexistent_attachments then
              new_attchmts << attchmt
            end
          else
              new_attchmts << attchmt
          end
        end
      end
    else
      $log.warn "no attachments specified"
    end
    if append then
      self.attachments.concat(new_attchmts)
    else  # replace
      self.attachments = new_attchmts
    end
  end

  # Assign references from 'spec' to self.references.
  pre 'spec-targets-exist' do |spec| ! spec.existing_targets.nil? end
  def assign_references spec
    if spec.references then
      @references = spec.references.split(SPEC_FIELD_DELIMITER)
      check_references spec
    end
  end

  ### Implementation/verification

  def check_fields
    # handle serves as an id and is mandatory.
    if not self.handle then $log.warn "No handle for #{self.title}" end
  end

  pre 'refs exist' do ! self.references.nil? end
  pre 'spec exists' do |spec| ! spec.nil? end
  pre 'extargets exist' do |spec| ! spec.existing_targets.nil? end
  pre 'extargets is-hash' do |spec| spec.existing_targets.is_a?(Hash) end
  def check_references spec
    ex_targets = spec.existing_targets
    myhandle = self.handle
    valid_refs = self.references.select do |r|
      if ex_targets.has_key?(r) then
        true
      else
        $log.warn "candidate ref for #{myhandle} is invalid: #{r}"
        false
      end
    end
    if spec.reject_false_references then
      self.references = valid_refs
    end
  end

  ### Implementation

  # Remove 'child' from 'children', set its parent_handle to nil, and
  # "adopt" its children as our (self's) own.
  pre '! child.nil?' do |child| ! child.nil? end
  post 'no longer a child' do |result, child| ! children.include?(child) end
  post 'no children' do |result, child| child.children.count == 0 end
  post 'no parent' do |result, child| child.parent_handle.nil? end
  def detach child
    remove_child child
    its_children = child.children
    its_children.each do |c|
      c.parent_handle = self.handle
      self.add_child c
      child.remove_child c
    end
    child.parent_handle = nil
  end

  ### Implementation - utilities/tools

  # Assign the specified 'spec' value to the attribute with name
  # 'attr_name', with the following guard:
  #    o if the "'spec' value" is nil or is an empty String, abort the
  #      assignment
  # If ! alt_name.nil? use it as the name of the "attribute" of 'spec' to
  # assign to self.<attr_name>; otherwise, use 'spec.<attr_name>'.
  pre 'args are valid' do |aname, spec| ! aname.nil? && ! spec.nil? end
  def guarded_scalar_assignment(attr_name, spec, alt_name = nil)
    if ! alt_name.nil? then
      specname = alt_name
    else
      specname = attr_name
    end
    new_value = spec.send(specname)
    if ! new_value.nil? then
      newval_valid = true
      if new_value.is_a?(String) then
        newval_valid = ! new_value.empty?
      end
      if newval_valid then
        self.send("#{attr_name}=", spec.send(specname))
      end
    end
  end

  # Constructed suffix for the subject/title/...
  def subject_suffix(client)
    result = ""
    cat_prefix = ""
    if client != nil then
      cat_prefix = client.configuration.category_prefix
    end
    if ! categories.empty? then
      result = ", #{cat_prefix}" + categories.join(", #{cat_prefix}")
    end
    result
  end

  def current_message_appendix
    now = Time.now
    result = "notification sent on: #{time_24hour(now)}\n"
    if ! children.empty? then
      result += "subordinates:\n"
      children.each do |t|
        tree = TreeNode.new(t)
        # Append to 'result' t's info and that of all of its descendants.
        result += tree.descendants_report(1) do |t|
          "#{time_24hour(t.time)}  #{t.title} (#{t.formal_type}:#{t.handle})"
        end
      end
    end
    uprem = upcoming_reminders(true)
    if ! uprem.empty? then
      result += "upcoming reminders: " + uprem.join('; ') + "\n"
    end
    result
  end

  def set_email_addrs
    emails = raw_email_addrs
    @initial_email_addrs = []
    @ongoing_email_addrs = []
    emails.each do |e|
      if not e.match(ONGOING_EMAIL_PTRN) then
        @initial_email_addrs << e.gsub(INITIAL_EMAIL_PTRN, "")
      end
      if not e.match(INITIAL_EMAIL_PTRN) then
        @ongoing_email_addrs << e.gsub(ONGOING_EMAIL_PTRN, "")
      end
    end
  end

  # Execute new-parent logic.
  def assign_parent parent_h, target_list
    if parent_h != nil then
      orig_parent = target_list[self.parent_handle]
      if parent_h == "" then
        @parent_handle = nil  # self becomes a top-level ancestor.
      else
        assert('parent_h not empty') { parent_h.length > 0 }
        self.parent_handle = parent_h
        new_parent = target_list[self.parent_handle]
        if new_parent.nil? then
          raise invalid_parent_handle_msg(self.handle, self.parent_handle)
        end
        if orig_parent.nil? || orig_parent.handle != parent_h then
          # self's parent has changed - add self to new parent:
          new_parent.add_child(self)
        end
      end
      if ! orig_parent.nil? && orig_parent.handle != parent_h then
        # The parent has been changed, so "un-adopt" the original parent.
        orig_parent.remove_child(self)
      end
    end
  end

  # Send an notification to all recipients designated as initial recipients.
  def send_initial_notifications(client)
    assert('initial_email_addrs != nil') { @initial_email_addrs != nil }
    if ! @initial_email_addrs.empty? then
      # Set notification components to be used by the 'notifiers'.
      @notification_subject = 'initial ' + current_message_subject +
        subject_suffix(client)
      @full_notification_message = current_message + current_message_appendix
      @notification_email_addrs = @initial_email_addrs
      @short_notification_message = ""
      notifiers.each do |n|
        n.send_message self
      end
    end
  end

  def set_initial_calendar_entry calentry
    if not calendar_ids.empty? then
      set_cal_fields calentry
      calendar_ids.each do |id|
        calentry.calendar_id = id
        if
          calentry.title != nil && calentry.time != nil
        then
          calentry.submit
        else
          msg = "Value(s) not set: "
          nils = []
          ['title', 'time'].select do |method|
            if calentry.send(method) == nil then
              nils << method
            end
          end
          msg += nils.join(', ') + " - skipping calendar submission"
          $log.warn "#{msg}"
        end
      end
    end
  end

  # Send a notification email to all recipients.
  def send_ongoing_notifications(client = nil)
    assert('ongoing_email_addrs != nil') { @ongoing_email_addrs != nil }
    rems = []
    reminders.each { |r| if r.is_due? then rems << r end }
    if
      final_reminder != nil and final_reminder.is_due?
    then
      rems << final_reminder
      final_reminder.addendum = "Final "
    end
    old_date_for = {}
    rems.each { |r| old_date_for[r] = r.date_time; r.trigger }
    rems.each do |r|
      if ! @ongoing_email_addrs.empty? then
        # Set notification components to be used by the 'notifiers'.
        @notification_subject = r.addendum + message_subject_label +
          current_message_subject + subject_suffix(client) +
          " #{old_date_for[r]}"
        @full_notification_message = current_message + current_message_appendix
        @notification_email_addrs = @ongoing_email_addrs
        @short_notification_message = ""
        notifiers.each do |n|
          n.send_message self
        end
      end
    end
    if ! rems.empty? and client != nil then
      client.dirty = true
    end
  end

  post 'result != nil' do |result| result != nil end
  def raw_email_addrs
    result = []
    if @email_spec then
      result = @email_spec.split(SPEC_FIELD_DELIMITER)
    end
    result
  end

  # email information for output (to_s)
  def email_info(template)
    result = ""
    if template then
      email_map = {:initial => [], :ongoing => []}
      email_set = Set.new
      @initial_email_addrs.each do |e|
        email_map[:initial] << e
        email_set << e
      end
      @ongoing_email_addrs.each do |e|
        email_map[:ongoing] << e
        email_set << e
      end
      emails = []
      email_set.each do |e|
        if email_map[:initial].include?(e) then
          if email_map[:ongoing].include?(e) then
            emails << e   # (Both initial and ongoing, so no tag.)
          else
            emails << e + INITIAL_EMAIL_TAG
          end
        else
          emails << e + ONGOING_EMAIL_TAG
        end
      end
      result = "email: " + emails.join(SPEC_FIELD_JOINER + ' ') + "\n"
    else
      if @initial_email_addrs != nil then
        result += "initial #{EMAIL_KEY}: #{@initial_email_addrs.join(', ')}\n"
      end
      if @ongoing_email_addrs != nil then
        result += "ongoing #{EMAIL_KEY}: #{@ongoing_email_addrs.join(', ')}\n"
      end
    end
    result
  end

  ### Hook routines

  # Set the fields of `calentry' from self's current state.
  def set_cal_fields calentry
    calentry.title = title
    calentry.description = description + description_appendix
  end

  # Additional information, if any, to add to the description
  post 'result != nil' do |result| result != nil end
  def description_appendix
    result = ""
    result
  end

  def to_s_appendix
    ""
  end

  ###  class invariant

  def invariant
    reminders != nil
  end

end
