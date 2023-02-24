require 'ruby_contracts'
require 'time'
require 'set'
require 'email'
require 'onetimereminder'
require 'spectools'
require 'timetools'
require 'treenode'
require 'targetstate'
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
  alias :description :content
  alias :name :handle
  alias :detail :comment
  attr_reader :notification_subject, :full_notification_message,
    :notification_email_addrs, :short_notification_message

  attr_writer :parent_handle
  attr_writer :handle         # Needed for cloning

  public

  ###  Access

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
  # post!!!!!: result != nil && (! can_have_children? implies result.empty?)
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

  ###  Comparison

  VERY_LATE = Time.parse('10000-01-01 00:00')

  def <=>(other)
    other_time = other.time != nil ? other.time : VERY_LATE
    mytime = time != nil ? time : VERY_LATE
    result = mytime <=> other_time
    result
  end

  ###  Status report

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

  ###  Element change

  # Add a STodoTarget object to 'children'.
  pre 't != nil and t.parent_handle == handle' do |t|
    ! t.nil? && t.parent_handle == handle
  end
  def add_child(t)
    @children << t
  end

  # Add a notifier to the list of notifiers to be used by `initiate' and
  # `perform_ongoing_actions'.
  # precondition:  n != nil
  # postcondition: notifiers.length == old notifiers.length + 1
  pre 'n != nil' do |n| n != nil end
  def add_notifier n
    @notifiers << n
  end

  # Set self's fields from the non-nil fields in spec.
  # precondition: ! spec.nil? && self.handle == spec.handle
  # precondition: ! target_list.nil? && target_list.is_a?(Hash)
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

  ###  Removal

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

  ###  Duplication

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
    orig.notifiers.each do |o|
      @notifiers << o.dup
    end
  end

  ###  Hash-related queries

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

  ###  Basic operations

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

  ###  Miscellaneous

  def descendants_report
    tree = TreeNode.new(self)
    tree.descendants_report do |t|
      "#{t.handle}, due: #{time_24hour(t.time)}"
    end
  end

  ###  Persistence

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

  attr_writer :last_removed_descendant

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
    if spec.categories then
      @categories = spec.categories.split(SPEC_FIELD_DELIMITER)
    else
      @categories = []
    end
    @calendar_ids = []
    if spec.calendar_ids != nil then
      @calendar_ids = spec.calendar_ids.split(SPEC_FIELD_DELIMITER)
      $log.debug "calendar_ids set: #{calendar_ids}"
    end
    if spec.parent != nil then
      self.parent_handle = spec.parent
    end
  end

  def check_fields
    # handle serves as an id and is mandatory.
    if not self.handle then $log.warn "No handle for #{self.title}" end
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
  pre '"spec" is valid' do |spec, target_list|
      ! spec.nil? && self.handle == spec.handle
  end
  pre 'target_list is valid' do |spec, target_list|
      ! target_list.nil? && target_list.is_a?(Hash)
  end
  post 'parent set as specified' do |result, spec, target_list|
    implies(spec.parent == "", self.parent_handle.nil?) &&
      implies(! spec.parent.nil? && spec.parent.length > 0,
              self.parent_handle == spec.parent && self.parent_handle ==
              target_list[self.parent_handle].handle)
  end
  def main_modify_fields spec, target_list
    @title = spec.title if spec.title
    @content = spec.description if spec.description
    @comment = spec.comment if spec.comment
    @priority = spec.priority if spec.priority
    if spec.email then
      @email_spec = spec.email
      set_email_addrs
    end
    if spec.parent != nil then
      orig_parent = target_list[self.parent_handle]
      if spec.parent == "" then
        @parent_handle = nil  # self becomes a top-level ancestor.
      else
        assert('spec.parent not empty') { spec.parent.length > 0 }
        self.parent_handle = spec.parent
        new_parent = target_list[self.parent_handle]
        if new_parent.nil? then
          raise invalid_parent_handle_msg(self.handle, self.parent_handle)
        end
        if orig_parent == nil || orig_parent.handle != spec.parent then
          # self's parent has changed - add self to new parent:
          new_parent.add_child(self)
        end
      end
      if orig_parent != nil && orig_parent.handle != spec.parent then
        # The parent has been changed, so "un-adopt" the original parent.
        orig_parent.remove_child(self)
      end
    end
    if spec.categories then
      @categories = spec.categories.split(SPEC_FIELD_DELIMITER)
    end
    if spec.calendar_ids != nil then
      @calendar_ids = spec.calendar_ids.split(SPEC_FIELD_DELIMITER)
    end
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
  # precondition: not spec.is_template? implies time != nil
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

  ### Implementation - utilities

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

  # postcondition: result != nil
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
  # postcondition: result != nil
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
