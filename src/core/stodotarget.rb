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

  public

  attr_reader :title, :content, :handle, :calendar_ids, :priority, :comment,
    :reminders, :categories, :parent_handle, :notifiers, :children, :state
  alias :description :content
  alias :name :handle
  alias :detail :comment
  attr_reader :notification_subject, :full_notification_message,
    :notification_email_addrs, :short_notification_message

  attr_writer :parent_handle

  public

  ###  Access

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
  # postcondition: result != nil && (! can_have_children? implies result.empty?)
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
  # postcondition:
  #   (state.value == IN_PROGRESS || state.value == SUSPENDED) implies
  #      result == nil
  def completion_date
    result = state.completion_time
    assert_postcondition('(state.value == IN_PROGRESS || ' +
        'state.value == SUSPENDED) implies result == nil') {
      implies(state.value == IN_PROGRESS || state.value == SUSPENDED,
              result == nil)
    }
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

  ###  Element change

  # Add a STodoTarget object to 'children'.
  # precondition: t != nil and t.parent_handle == handle
  def add_child(t)
    assert_precondition('t != nil and t.parent_handle == handle') do
      t != nil and t.parent_handle == handle
    end
    @children << t
  end

  # Add a notifier to the list of notifiers to be used by `initiate' and
  # `perform_ongoing_actions'.
  # precondition:  n != nil
  # postcondition: notifiers.length == old notifiers.length + 1
  def add_notifier n
    assert_precondition('n != nil') { n != nil }
    @notifiers << n
  end

  # Set self's fields from the non-nil fields in spec.
  # precondition: spec != nil && handle == spec.handle
  def modify_fields spec
    main_modify_fields spec
    post_modify_fields spec
  end

  ###  Removal

  # Remove child `t' from 'children'.
  def remove_child t
    @children.delete(t)
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
  def initiate calendar
    send_initial_notifications
    set_initial_calendar_entry calendar
  end

  # Perform post-"initiate" notifications.
  def perform_ongoing_actions(status_client = nil)
    if state.value == IN_PROGRESS then
      send_ongoing_notifications(status_client)
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

  ###  Initialization

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
    assert_invariant {invariant}
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
      @parent_handle = spec.parent
    end
  end

  def check_fields
    # handle serves as an id and is mandatory.
    if not self.handle then $log.warn "No handle for #{self.title}" end
  end

  def main_modify_fields spec
    assert_precondition('spec != nil && handle == spec.handle') {
      spec != nil && handle == spec.handle }
    @title = spec.title if spec.title
    @email_spec = spec.email if spec.email
    @content = spec.description if spec.description
    @comment = spec.comment if spec.comment
    @priority = spec.priority if spec.priority
    if spec.parent != nil then
      @parent_handle = spec.parent
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
  def reminders_from_spec spec
    assert_precondition('not spec.is_template? implies time != nil') {
      implies(! spec.is_template?, time != nil)
    }
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

  ### Implementation - utilities

  # Constructed suffix for the subject/title/...
  def subject_suffix
    result = ""
    if ! categories.empty? then
      cat = categories.length > 1 ? 'cats: ' : 'cat: '
      result = ", #{cat}" + categories.join(', ')
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
  def send_initial_notifications
    assert('initial_email_addrs != nil') { @initial_email_addrs != nil }
    if ! @initial_email_addrs.empty? then
      # Set notification components to be used by the 'notifiers'.
      @notification_subject = 'initial ' + current_message_subject +
        subject_suffix
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
          calentry.duration != nil && calentry.title != nil &&
          calentry.time != nil
        then
          calentry.submit
        else
          msg = "Value(s) not set: "
          nils = []
          ['duration', 'title', 'time'].select do |method|
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
  def send_ongoing_notifications(status_client = nil)
    assert('ongoing_email_addrs != nil') { @ongoing_email_addrs != nil }
    rems = []
    reminders.each { |r| if r.is_due? then rems << r end }
    if
      final_reminder != nil and final_reminder.is_due?
    then
      rems << final_reminder
      final_reminder.addendum = "Final "
    end
    rems.each do |r|
      if ! @ongoing_email_addrs.empty? then
        # Set notification components to be used by the 'notifiers'.
        @notification_subject = r.addendum + message_subject_label +
          current_message_subject + subject_suffix + " #{r.date_time}"
        @full_notification_message = current_message + current_message_appendix
        @notification_email_addrs = @ongoing_email_addrs
        @short_notification_message = ""
        notifiers.each do |n|
          n.send_message self
        end
      end
      r.trigger
    end
    if ! rems.empty? and status_client != nil then
      status_client.dirty = true
    end
  end

  # postcondition: result != nil
  def raw_email_addrs
    result = []
    if @email_spec then
      result = @email_spec.split(SPEC_FIELD_DELIMITER)
    end
    assert_postcondition('result != nil') { result != nil }
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
  def description_appendix
    result = ""
    assert_postcondition('result != nil') { result != nil }
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
