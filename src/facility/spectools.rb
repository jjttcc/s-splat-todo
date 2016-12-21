# STodoSpec-related tools
module SpecTools
  # constants - s*todo-target-field names/hash-keys:
  TYPE_KEY, TITLE_KEY, DESCRIPTION_KEY, HANDLE_KEY, PRIORITY_KEY, DUE_DATE_KEY,
    GOAL_KEY, EMAIL_KEY, COMMENT_KEY, PARENT_KEY, REMINDER_KEY, START_DATE_KEY,
    EXPIRATION_DATE_KEY, DATE_TIME_KEY, DURATION_KEY, LOCATION_KEY,
    CALENDAR_IDS_KEY, CATEGORIES_KEY =
    'type', 'title', 'description', 'handle', 'priority', 'due_date', 'goal',
    'email', 'comment', 'parent', 'reminders', 'start_date', 'expiration_date',
    'date_time', 'duration', 'location', 'calendar_ids', 'categories'
  SINGULAR_REMINDER_KEY = 'reminder'
  SPEC_FIELD_DELIMITER = /,\s*/
  SPEC_FIELD_JOINER = ','
  REMINDER_DELIMITER = /;\s*/
  DEFAULT_LOG_PATH = "/tmp/stodo-debug-#{$$}"

  # constants - s*todo-target-types and aliases:
  TASK, APPOINTMENT, NOTE, PROJECT, CORRECTION = 'task', 'appointment',
    'note', 'project', 'correction'
  TEMPLATE_TYPE = 'template'
  TASK_ALIAS1, APPOINTMENT_ALIAS1, APPOINTMENT_ALIAS2, NOTE_ALIAS1,
    NOTE_ALIAS2 = 'action', 'meeting', 'event', 'memorandum', 'memo'


  # system-wide constants - Env vars:
  STDEBUG = 'STODO_DEBUG'
  STTESTRUN = 'STODO_TEST'
  STLOG_LEVEL = 'STODO_LOG_LEVEL'
  ST_CONFIG_PATH = 'STODO_CONFIG_PATH'
  ST_LOG_PATH = 'STODO_LOG'
  STODO_PATH = 'STODO_PATH'

  # tags/patterns from spec with special meaning
  INITIAL_EMAIL_PTRN = Regexp.new('\[initial\]')
  ONGOING_EMAIL_PTRN = Regexp.new('\[ongoing\]')
  SUBJECT_TEMPLATE_PTRN = Regexp.new('<subject>')
  ADDRS_TEMPLATE_PTRN = Regexp.new('<addrs>')
  INITIAL_EMAIL_TAG = '[initial]'
  ONGOING_EMAIL_TAG = '[ongoing]'

end
