require_relative 'stodospec'

# Stubbed-out STodoSpec, for templating
class StubbedSpec < STodoSpec

  private

  def initialize type
    @setting_for = {}
    @setting_for[TYPE_KEY] = type
    set_fields
  end

  def set_fields
    expire_date = DateTime.now + 30
    @setting_for[TITLE_KEY] = ''
    @setting_for[DESCRIPTION_KEY] = ''
    @setting_for[HANDLE_KEY] = '<unique-handle1>'
    @setting_for[PRIORITY_KEY] = ''
    @setting_for[DUE_DATE_KEY] = Time.now.to_s
    @setting_for[GOAL_KEY] = ''
    @setting_for[EMAIL_KEY] = 'template@template.org'
    @setting_for[COMMENT_KEY] = ''
    @setting_for[PARENT_KEY] = ''
    @setting_for[REMINDER_KEY] = ''
    @setting_for[START_DATE_KEY] = ''
    @setting_for[EXPIRATION_DATE_KEY] = expire_date.to_s
    @setting_for[DATE_TIME_KEY] = Time.now.to_s
    @setting_for[DURATION_KEY] = ''
    @setting_for[LOCATION_KEY] = ''
    @setting_for[CALENDAR_IDS_KEY] = ''
    @setting_for[CATEGORIES_KEY] = ''
  end

end
