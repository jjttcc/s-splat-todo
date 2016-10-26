require_relative 'email'
require_relative 'reminder'
require_relative 'spectools'

# Items - actions, projects, appointments, etc. - to keep track of, not
# forget about, and/or complete
class STodoTarget
  include SpecTools

  attr_reader :title, :content, :handle, :email_spec, :calendar_ids,
    :priority, :comment, :reminders, :categories, :initial_email_addrs,
    :ongoing_email_addrs, :parent_handle
  alias :description :content
  alias :name :handle
  alias :detail :comment

  attr_writer :parent_handle

  public

  ###  Status report

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
  def initiate manager
    send_initial_emails manager.mailer
    set_initial_calendar_entry manager.calendar
  end

  # Perform post-"initiate" notifications.
  def perform_ongoing_actions manager
    send_notification_emails manager.mailer
  end

  private

  ###  Initialization

  def initialize spec
    @valid = true
    set_fields spec
    check_fields
    set_email_addrs
  end

  def set_fields spec
    @title = spec.title
    @handle = spec.handle
    @email_spec = spec.email
    @content = spec.description
    @comment = spec.comment
    @reminders = reminders_from_spec spec
if @reminders then $log.debug "#{handle}'s reminders:"
@reminders.each do |r|
  $log.debug "#{r.date_time.to_time}, expired? #{r.expired?}"
end
end
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
$log.debug "[#{handle}]"
$log.debug "initemails: #{@initial_email_addrs}"
$log.debug "ongemails: #{@ongoing_email_addrs}"
  end

  # Send an email to all recipients designated as initial recipients.
  def send_initial_emails mailer
    subject = 'initial ' + email_subject
    email = Email.new(initial_email_addrs, subject, email_body)
    if not email.to_addrs.empty? then
      email.send mailer
    end
  end

  def set_initial_calendar_entry calentry
    #!!!!Needed enhancement: take reminder dates/times into account based
    # on self's type - e.g., Memorandum should probably create a calendar
    # entry for each of its reminder-dates.
    if not calendar_ids.empty? then
      set_cal_fields calentry
      calendar_ids.each do |id|
        calentry.calendar_id = id
        calentry.submit
      end
    end
  end

  # Send a notification email to all recipients.
  def send_notification_emails mailer
    rems = []
    reminders.each { |r| if r.is_due? then rems << r end }
    rems.each do |r|
$log.debug "r.date_time, r.is_due?: #{r.date_time}, #{r.is_due?}"
      subject = "Reminder: #{r.date_time}: " + email_subject
      email = Email.new(ongoing_email_addrs, subject, email_body + r)
      if not email.to_addrs.empty? then
        email.send mailer
      end
      r.trigger
    end
  end

  # postcondition: result != nil
  def raw_email_addrs
    result = []
    if email_spec then
      result = email_spec.split(SPEC_FIELD_DELIMITER)
    end
    raise PostconditionError, 'result != nil' if result == nil
    result
  end

  ### Hook routines

  def email_subject
    raise "<email_subject> descendant class-method implementation required" +
      " [title: #{title}]"
  end

  def email_body
    raise "<email_body> descendant class-method implementation required" +
      " [title: #{title}]"
  end

  # Set the fields of `calentry' from self's current state.
  def set_cal_fields calentry
    calentry.title = title
    calentry.description = description + description_appendix
  end

  # Additional information, if any, to add to the description
  # postcondition: result != nil
  def description_appendix
    result = ""
  end

end
