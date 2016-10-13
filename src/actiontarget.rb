require_relative 'email'
require_relative 'spectools'

# Targets of one or more actions to be executed by the system
#!!!!NOTE: This class may need to change its name - to find a good name, try
#coming up with a good (better) description first.  (TodoTarget?)
module ActionTarget
  include SpecTools

  attr_reader :title, :content, :handle, :email, :calendar, :priority,
    :comment, :reminder_dates, :categories
  alias :description :content
  alias :name :handle
  alias :detail :comment

  public

  ###  Access

  # Calendar handles for "self"
  def calendar_handles
    if @calendar_specs == nil then
      # (!!!Extract the calendar specs.)
    end
    @calendar_specs
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

  # Perform required initial actions.
  def initiate manager
    send_initial_emails manager.mailer
    set_initial_calendar_entry manager.calendar
  end

  #!!!!!Need a better method name!!!!!
  def perform_current_actions manager
    send_notification_emails manager.mailer
  end

  private

  ###  Initialization

  def initialize spec
    set_fields spec
    check_fields
  end

  def set_fields spec
    @title = spec.title
    @handle = spec.handle
    @email = spec.email
    @calendar = spec.calendar
    @content = spec.description
    @reminder_dates = date_times_from_reminders spec
    if spec.categories then
      @categories = spec.categories.split(/,\s*/)
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

  # Send an email to all recipients designated as initial recipients.
  def send_initial_emails mailer
    subject = 'initial ' + email_subject
    email = Email.new(initial_email_recipients, subject, email_body)
##!!!Add cc, bcc...!!!
    if not email.to_addrs.empty? then
      email.send mailer
    end
  end

  def set_initial_calendar_entry calendar
  end

  # Send a notification email to all recipients.
  def send_notification_emails mailer
    subject = 'ongoing ' + email_subject
    email = Email.new(email_recipients, subject, email_body)
##!!!Add cc, bcc...!!!
    if not email.to_addrs.empty? then
      email.send mailer
    end
  end

  # Email address of the designated recipients of notification/reminder about
  # "self"
  def email_recipients
    if @raw_email_addrs == nil then
      @raw_email_addrs = raw_email_addrs
    end
    if @email_addrs == nil then
      @email_addrs = @raw_email_addrs.map { |a|
        a.gsub(INITIAL_EMAIL_PTRN, "")
      }
    end
    @email_addrs
  end

  # Email address designated to be recipients of the initial (initiate)
  # emails
  def initial_email_recipients
    if @raw_email_addrs == nil then
      @raw_email_addrs = raw_email_addrs
    end
    if @initial_email_addrs == nil then
      @initial_email_addrs = @raw_email_addrs.grep(INITIAL_EMAIL_PTRN) { |a|
        a.gsub(INITIAL_EMAIL_PTRN, "")
      }
    end
    @initial_email_addrs
  end

  def raw_email_addrs
    result = []
    e = email
    if e then
      result = e.split(/,\s*/)
    end
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


end
