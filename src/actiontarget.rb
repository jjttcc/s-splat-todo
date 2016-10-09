# Targets of one or more actions to be executed by the system
module ActionTarget
  attr_reader :title, :content, :handle, :media, :priority, :comment,
    :reminder_dates
  alias :description :content
  alias :name :handle
  alias :detail :comment

  public

  # Email address of the designated recipients of notification/reminder about
  # the ActionTarget
  def email_recipients
    if @email_addrs == nil then
      # (!!!Extract the email addresses, if any, from 'media'.)
    end
    @email_addrs
  end

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

  private

  protected

  attr_reader :manager

  def initialize spec
    set_fields spec
    check_fields
    @manager.register self
  end

  def set_fields spec
    @title = spec.title
    @handle = spec.handle
    @media = spec.media
    @content = spec.content
    @manager = spec.action_manager
    @reminder_dates = date_times_from_reminders spec
  end

  def check_fields
    # handle serves as an id and is mandatory.
    if not self.handle then $log.warn "No handle for #{self.title}" end
    if not self.manager then $log.warn "No action manager for #{self.title}" end
  end

  def date_times_from_reminders spec
    # Extract the list of reminders from spec.reminders.
  end
end
