require_relative 'email'
require_relative 'spectools'

# Targets of one or more actions to be executed by the system
#!!!!NOTE: This class may need to change its name - to find a good name, try
#coming up with a good (better) description first.  (TodoTarget?)
module ActionTarget
  include SpecTools

  attr_reader :title, :content, :handle, :email, :calendar, :priority,
    :comment, :reminder_dates
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

  def initiate manager
    send_initial_emails manager.mailer
    set_initial_calendar_entry manager.calendar
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
    @content = spec.content
    @reminder_dates = date_times_from_reminders spec
  end

  def check_fields
    # handle serves as an id and is mandatory.
    if not self.handle then $log.warn "No handle for #{self.title}" end
  end

  def date_times_from_reminders spec
    # Extract the list of reminders from spec.reminders.
  end

  ### Implementation - utilities

  def send_initial_emails mailer
#testemail = Email.new(email_recipients, email_subject, email_body)
#puts "[#{title}]testemail: #{testemail.inspect}"
    email = Email.new(initial_email_recipients, email_subject, email_body)
#puts "[#{title}]initemail: #{email.inspect}"
    ##!!!Add cc, bcc...!!!
    email.send mailer
  end

  def set_initial_calendar_entry calendar
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
  end

  def email_body
  end


end
