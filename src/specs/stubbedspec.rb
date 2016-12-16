require 'stodospec'

# Stubbed-out STodoSpec, for templating
class StubbedSpec < STodoSpec

  public

  def is_template?
    true
  end

  private

  def initialize options
    @setting_for = {}
    @setting_for[TYPE_KEY] = options.type
    set_fields options
  end

  def set_fields options
    expire_date = DateTime.now + 30
    handle = options.handle.empty? ? '<unique-handle1>' : options.handle
    email = options.email.empty? ? '<template>@<template.org>' : options.email
    due_time = options.time.empty? ? Time.now.to_s : options.time
    expire_date = options.time.empty? ? DateTime.now + 30 : options.time
    @setting_for[TITLE_KEY] = options.title
    @setting_for[DESCRIPTION_KEY] = options.description
    @setting_for[HANDLE_KEY] = options.handle
    @setting_for[HANDLE_KEY] = handle
    @setting_for[PRIORITY_KEY] = options.priority
    @setting_for[DUE_DATE_KEY] = due_time
    @setting_for[GOAL_KEY] = ''
    @setting_for[EMAIL_KEY] = email
    @setting_for[COMMENT_KEY] = ''
    @setting_for[PARENT_KEY] = options.parent
    @setting_for[REMINDER_KEY] = ''
    @setting_for[START_DATE_KEY] = ''
    @setting_for[EXPIRATION_DATE_KEY] = expire_date.to_s
    @setting_for[DATE_TIME_KEY] = options.time
    @setting_for[DURATION_KEY] = options.duration
    @setting_for[LOCATION_KEY] = options.location
    @setting_for[CALENDAR_IDS_KEY] = options.calendar_ids
    @setting_for[CATEGORIES_KEY] = options.categories
  end

end
