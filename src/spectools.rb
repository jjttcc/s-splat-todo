# STodoSpec-related tools
module SpecTools
  # constants - s*todo-target-types:
  TYPE_KEY, TITLE_KEY, DESCRIPTION_KEY, HANDLE_KEY, PRIORITY_KEY, DUE_DATE_KEY,
    GOAL_KEY, EMAIL_KEY, COMMENT_KEY, PARENT_KEY, REMINDER_KEY, START_DATE_KEY,
    EXPIRATION_DATE_KEY, DATE_TIME_KEY, DURATION_KEY, LOCATION_KEY,
    CALENDAR_KEY =
    'type', 'title', 'description', 'handle', 'priority', 'due_date', 'goal',
    'email', 'comment', 'parent', 'reminders', 'start_date', 'expiration_date',
    'date_time', 'duration', 'location', 'calendar'

  # system-wide constants:
  STDEBUG = 'STODO_DEBUG'

  # tags/patterns from spec with special meaning
  INITIAL_EMAIL_PTRN = Regexp.new('\[send-initial\]')
end
