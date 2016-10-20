require_relative 'email'
require_relative 'spectools'

# Items - actions, projects, appointments, etc. - to keep track of, not
# forget about, and/or complete
class STodoTarget
  include SpecTools

  attr_reader :title, :content, :handle, :email_spec, :calendar_ids,
    :priority, :comment, :reminder_dates, :categories,
    :initial_email_addrs, :ongoing_email_addrs
  alias :description :content
  alias :name :handle
  alias :detail :comment

  public

  ###  Status report

  def formal_type
    self.class
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

  # postcondition: @raw_email_addrs != nil
  def initialize spec
    set_fields spec
    check_fields
    set_email_addrs
#!!!@raw_email_addrs = raw_email_addrs
#!!!raise PostconditionError, '@raw_email_addrs != nil' if ! @raw_email_addrs
  end

  def set_fields spec
    @title = spec.title
    @handle = spec.handle
    @email_spec = spec.email
    @content = spec.description
    @comment = spec.comment
    @reminder_dates = date_times_from_reminders spec
    if spec.categories then
      @categories = spec.categories.split(/,\s*/)
    end
    @calendar_ids = []
    if spec.calendar_ids != nil then
      @calendar_ids = spec.calendar_ids.split(/,\s*/)
    end
  end

  def check_fields
    # handle serves as an id and is mandatory.
    if not self.handle then $log.warn "No handle for #{self.title}" end
  end

  def date_times_from_reminders spec
    # Extract the list of reminders from spec.reminders.
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
#!!!email = Email.new(initial_email_recipients, subject, email_body)
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
    subject = 'ongoing ' + email_subject
#!!!email = Email.new(ongoing_email_recipients, subject, email_body)
    email = Email.new(ongoing_email_addrs, subject, email_body)
    if not email.to_addrs.empty? then
      email.send mailer
    end
  end

  # Email address of the designated recipients of notification/reminder about
  # "self"
  # precondition: @raw_email_addrs != nil
  def old_____ongoing_email_recipients
    raise PreconditionError, '@raw_email_addrs != nil' if ! @raw_email_addrs
    if @ongoing_email_addrs == nil then
      @ongoing_email_addrs = []
      @raw_email_addrs.each do |e|
        if not e.match(INITIAL_EMAIL_PTRN) then
          @ongoing_email_addrs << e.gsub(ONGOING_EMAIL_PTRN, "")
        end
      end
    end

=begin
    if @email_addrs == nil then
      @email_addrs = @raw_email_addrs.map { |a|
        a.gsub(INITIAL_EMAIL_PTRN, "")
      }
    end
    @email_addrs
=end
  end

  # Email address designated to be recipients of the initial (initiate)
  # emails
  # precondition: @raw_email_addrs != nil
  def old_____initial_email_recipients
    raise PreconditionError, '@raw_email_addrs != nil' if ! @raw_email_addrs
#grap addrs without the ONGOING_EMAIL_PTRN
    if @initial_email_addrs == nil then
      @initial_email_addrs = []
      @raw_email_addrs.each do |e|
        if not e.match(ONGOING_EMAIL_PTRN) then
          @initial_email_addrs << e.gsub(INITIAL_EMAIL_PTRN, "")
        end
      end
    end
    @initial_email_addrs
  end

  # postcondition: result != nil
  def raw_email_addrs
    result = []
    if email_spec then
      result = email_spec.split(/,\s*/)
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
