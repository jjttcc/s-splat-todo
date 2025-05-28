require 'stodospec'

# Stubbed-out STodoSpec, for templating
class StubbedSpec < STodoSpec

  public

  def is_template?
    true
  end

  private

  def initialize options, use_defaults = true
    @setting_for = {}
    @setting_for[TYPE_KEY] = options.type
    set_fields options, use_defaults
  end

  def set_fields options, use_defaults
    handle = options.handle
    email = options.email
    due_time = options.time
    expire_date = options.time
    if use_defaults then
      if handle.nil? || handle.empty? then
        handle = '<unique-handle1>'
      end
      if email.nil? || email.empty? then
        email = '<template>@<template.org>'
      end
      if due_time.nil? || due_time.nil? then
        due_time = Time.now.to_s
      end
      if expire_date.nil? || expire_date.nil? then
        expire_date = DateTime.now + 30
      end
    else
      if ! handle.nil? && handle.empty? then
        handle = nil
      end
      if ! email.nil? && email.empty? then
        email = nil
      end
    end
    @setting_for[TITLE_KEY] = options.title
    @setting_for[DESCRIPTION_KEY] = options.description
    @setting_for[APPEND_DESCRIPTION_KEY] = options.appended_description
    @setting_for[HANDLE_KEY] = options.handle
    @setting_for[HANDLE_KEY] = handle
    @setting_for[PRIORITY_KEY] = options.priority
    @setting_for[DUE_DATE_KEY] = due_time
    @setting_for[GOAL_KEY] = ''
    @setting_for[EMAIL_KEY] = email
    @setting_for[COMMENT_KEY] = ''
    @setting_for[PARENT_KEY] = options.parent
    @setting_for[START_DATE_KEY] = ''
    @setting_for[EXPIRATION_DATE_KEY] = expire_date.to_s
    @setting_for[DATE_TIME_KEY] = options.time
    @setting_for[DURATION_KEY] = options.duration
    @setting_for[LOCATION_KEY] = options.location
    @setting_for[CALENDAR_IDS_KEY] = options.calendar_ids
    @setting_for[CATEGORIES_KEY] = options.categories
    @setting_for[ATTACHMENTS_KEY] = options.attachments
    @setting_for[REFERENCES_KEY] = options.references
    @setting_for[REMINDER_KEY] = options.reminders
    @setting_for[APPEND_REMINDER_KEY] = options.appended_reminders
    @setting_for[COMMIT_MSG_KEY] = options.commit_message
  end

end
