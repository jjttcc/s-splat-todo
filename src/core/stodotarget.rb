require 'email'
require 'reminder'
require 'spectools'

# Items - actions, projects, appointments, etc. - to keep track of, not
# forget about, and/or complete
class STodoTarget
  include SpecTools, ErrorTools

  public

  attr_reader :title, :content, :handle, :calendar_ids, :priority, :comment,
    :reminders, :categories, :parent_handle, :notifiers
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
        v = (tag == DESCRIPTION_KEY) ? self.description : ""
      end
      result += "#{tag}: #{v}\n"
    end
    result += "#{REMINDER_KEY}: #{reminders.join(', ')}\n"
    if @initial_email_addrs != nil then
      result += "#{EMAIL_KEY}: #{@initial_email_addrs.join(', ')}\n"
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

  ###  Status report

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

  def can_have_children?
    false
  end

  # Does 'self' have a parent?
  def has_parent?
    self.parent_handle != nil
  end

  ###  Element change

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
    if spec.categories then
      @categories = spec.categories.split(SPEC_FIELD_DELIMITER)
    end
    if spec.calendar_ids != nil then
      @calendar_ids = spec.calendar_ids.split(SPEC_FIELD_DELIMITER)
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
  def initiate calendar
    send_initial_notifications
    set_initial_calendar_entry calendar
  end

  # Perform post-"initiate" notifications.
  def perform_ongoing_actions
    send_ongoing_notifications
  end

  private

  ###  Initialization

  def initialize spec
    @valid = true
    set_fields spec
    check_fields
    set_email_addrs
    @notifiers = []
  end

  def set_fields spec
    @title = spec.title
    @handle = spec.handle
    @email_spec = spec.email
    @content = spec.description
    @comment = spec.comment
    @priority = spec.priority
    @reminders = reminders_from_spec spec
    if spec.categories then
      @categories = spec.categories.split(SPEC_FIELD_DELIMITER)
    end
    @calendar_ids = []
    if spec.calendar_ids != nil then
      @calendar_ids = spec.calendar_ids.split(SPEC_FIELD_DELIMITER)
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
    if categories then
      result = ", cat: " + categories.join(', cat: ')
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
      @full_notification_message = current_message
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
  def send_ongoing_notifications
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
        @full_notification_message = current_message
        @notification_email_addrs = @ongoing_email_addrs
        @short_notification_message = ""
        notifiers.each do |n|
          n.send self
        end
      end
      r.trigger
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

  def marshal_dump
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
      'valid' => @valid,
      'parent_handle' => parent_handle
    }
  end

  def marshal_load(data)
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
    @valid = data['valid']
    @parent_handle = data['parent_handle']
    @notifiers = []
  end

  ###  class invariant

  def invariant
    true
  end

end
