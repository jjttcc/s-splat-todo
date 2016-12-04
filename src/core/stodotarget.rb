require 'time'
require 'set'
require 'email'
require 'reminder'
require 'spectools'
require 'timetools'
require 'treenode'
require 'targetstate'

# Items - actions, projects, appointments, etc. - to keep track of, not
# forget about, and/or complete
class STodoTarget
  include SpecTools, ErrorTools, TimeTools

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
  def to_s
    result = "#{TYPE_KEY}: #{spec_type}\n"
    for tag in [TITLE_KEY, HANDLE_KEY, DESCRIPTION_KEY, PRIORITY_KEY,
                COMMENT_KEY, PARENT_KEY] do
      v = self.instance_variable_get("@#{tag}")
      if v == nil then  # (description is an alias, not an attribute.)
        case tag
        when DESCRIPTION_KEY
          result += "status: #{state}\n"
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
      time_24hour(r.time)
    end
    result += remlist.join(', ') + "\n"
    if @initial_email_addrs != nil then
      result += "initial #{EMAIL_KEY}: #{@initial_email_addrs.join(', ')}\n"
    end
    if @ongoing_email_addrs != nil then
      result += "ongoing #{EMAIL_KEY}: #{@ongoing_email_addrs.join(', ')}\n"
    end
    result += "#{CALENDAR_IDS_KEY}: #{calendar_ids.join(', ')}\n"
    result += "#{CATEGORIES_KEY}: #{categories.join(', ')}\n"
    result + to_s_appendix
  end

  # All 'reminders' that are in the future
  def upcoming_reminders
    now = Time.now
    result = reminders.select do |r|
      r.time > now
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

  ###  Comparison

  VERY_LATE = Time.parse('10000-01-01 00:00')

  def <=>(other)
    other_time = other.time != nil ? other.time : VERY_LATE
    mytime = time != nil ? time : VERY_LATE
    result = mytime <=> other_time
    result
  end

  ###  Status report

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
    assert_precondition('spec != nil && handle == spec.handle') {
      spec != nil && handle == spec.handle }
    @title = spec.title if spec.title
    @email_spec = spec.email if spec.email
    @content = spec.description if spec.description
    @comment = spec.comment if spec.comment
    @priority = spec.priority if spec.priority
    @reminders = reminders_from_spec spec if spec.reminders != nil
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
    send_ongoing_notifications(status_client)
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
  end

  private

  ###  Initialization

  def initialize spec
    @valid = true
    set_fields spec
    check_fields
    set_email_addrs
    @notifiers = []
    @state = TargetState.new
  end

  def set_fields spec
    @children = Set.new
    @title = spec.title
    @handle = spec.handle
    @email_spec = spec.email
    @content = spec.description
    @comment = spec.comment
    @priority = spec.priority
    @reminders = reminders_from_spec spec
    if spec.categories then
      @categories = spec.categories.split(SPEC_FIELD_DELIMITER)
    else
      @categories = []
    end
    @calendar_ids = []
    if spec.calendar_ids != nil then
      @calendar_ids = spec.calendar_ids.split(SPEC_FIELD_DELIMITER)
    end
    if spec.parent != nil then
      @parent_handle = spec.parent
    end
  end

  def check_fields
    # handle serves as an id and is mandatory.
    if not self.handle then $log.warn "No handle for #{self.title}" end
  end

  def reminders_from_spec spec
    reminders_string = spec.reminders
    result = []
    if reminders_string != nil then
      reminders_string.split(SPEC_FIELD_DELIMITER).each do |r|
        begin
          rem = Reminder.new(r)
          result << Reminder.new(r)
        rescue Exception => e
          $log.warn "#{handle}: #{e.message}"
          @valid = false  # (1 or more bad reminders makes 'self' invalid.)
          break
        end
      end
    end
    result.sort
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
    result = ""
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
        n.send self
      end
    end
  end

  def set_initial_calendar_entry calentry
    if not calendar_ids.empty? then
      set_cal_fields calentry
      calendar_ids.each do |id|
        calentry.calendar_id = id
        calentry.submit
      end
    end
  end

  # Send a notification email to all recipients.
  def send_ongoing_notifications(status_client = nil)
    assert('ongoing_email_addrs != nil') { @ongoing_email_addrs != nil }
    rems = []
    reminders.each { |r| if r.is_due? then rems << r end }
    if
      final_reminder != nil and ! final_reminder.triggered? and
        final_reminder.is_due?
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
          n.send self
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

  ###  Persistence

  def old_remove__marshal_dump
    {
      'title' => title,
      'content' => content,
      'handle' => handle,
      'calendar_ids' => calendar_ids,
      'priority' => priority,
      'comment' => comment,
      'reminders' => reminders,
      'categories' => categories,
      'initial_email_addrs' => @initial_email_addrs,
      'ongoing_email_addrs' => @ongoing_email_addrs,
      'children' => children,
      'valid' => @valid,
      'parent_handle' => parent_handle
    }
  end

  def old_remove__marshal_load(data)
    @title = data['title']
    @content = data['content']
    @handle = data['handle']
    @calendar_ids = data['calendar_ids']
    @priority = data['priority']
    @comment = data['comment']
    @reminders = data['reminders']
    @categories = data['categories']
    @initial_email_addrs = data['initial_email_addrs']
    @ongoing_email_addrs = data['ongoing_email_addrs']
    @children = data['children']
    @valid = data['valid']
    @parent_handle = data['parent_handle']
    @notifiers = []
  end

  ###  class invariant

  def invariant
    true
  end

end
