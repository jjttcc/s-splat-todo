# STodoSpec-related tools
module SpecTools
  # constants - s*todo-target-field names/hash-keys:
  TYPE_KEY, TITLE_KEY, DESCRIPTION_KEY, HANDLE_KEY, PRIORITY_KEY, DUE_DATE_KEY,
    GOAL_KEY, EMAIL_KEY, COMMENT_KEY, PARENT_KEY, REMINDER_KEY, START_DATE_KEY,
    EXPIRATION_DATE_KEY, DATE_TIME_KEY, DURATION_KEY, LOCATION_KEY,
    CALENDAR_IDS_KEY, CATEGORIES_KEY, ATTACHMENTS_KEY, REFERENCES_KEY =
    'type', 'title', 'description', 'handle', 'priority', 'due_date', 'goal',
    'email', 'comment', 'parent', 'reminders', 'start_date', 'expiration_date',
    'date_time', 'duration', 'location', 'calendar_ids', 'categories',
    'attachments', 'references'
  SINGULAR_REMINDER_KEY = 'reminder'
  SPEC_FIELD_DELIMITER = /,\s*/
  SPEC_FIELD_JOINER = ','
  REMINDER_DELIMITER = /;\s*/
  DEFAULT_LOG_PATH = "/tmp/stodo-debug-#{$$}"

  # constants - s*todo-target-types and aliases:
  TASK, APPOINTMENT, NOTE, PROJECT, CORRECTION, EDIT = 'task', 'appointment',
    'note', 'project', 'correction', 'edit'
  TEMPLATE_TYPE = 'template'
  TASK_ALIAS1, APPOINTMENT_ALIAS1, APPOINTMENT_ALIAS2, NOTE_ALIAS1,
    NOTE_ALIAS2 = 'action', 'meeting', 'event', 'memorandum', 'memo'


  # system-wide constants - Env vars:
  STDEBUG               = 'STODO_DEBUG'
  STTESTRUN             = 'STODO_TEST'
  STLOG_LEVEL           = 'STODO_LOG_LEVEL'
  ST_CONFIG_PATH        = 'STODO_CONFIG_PATH'
  ST_LOG_PATH           = 'STODO_LOG'
  STODO_PATH            = 'STODO_PATH'
  ST_REJECT_BADREFS     = 'STODO_REJECT_BADREFS'
  ST_REJECT_BADATTCHMTS = 'STODO_REJECT_BADATTCHMTS'
  ST_ATTCH_ACTION       = 'ST_ATTCH_ACTION'

  # tags/patterns from spec with special meaning
  INITIAL_EMAIL_PTRN = Regexp.new('\[initial\]')
  ONGOING_EMAIL_PTRN = Regexp.new('\[ongoing\]')
  SUBJECT_TEMPLATE_PTRN = Regexp.new('<subject>')
  ADDRS_TEMPLATE_PTRN = Regexp.new('<addrs>')
  INITIAL_EMAIL_TAG = '[initial]'
  ONGOING_EMAIL_TAG = '[ongoing]'
  NONE = 'none'

  # application-level error messages
  HANDLE_TAG = '<handle>'
  P_HANDLE_TAG = '<parent_handle>'
  N_HANDLE_TAG = '<new_handle>'
  INVALID_PARENT_HANDLE_TEMPLATE =
    "Error in spec for item with handle \"<handle>\": "\
    "new parent handle \"<parent_handle>\", is not valid."
  RECURSIVE_PARENT_HANDLE_TEMPLATE =
    "Error in spec for item with handle \"<handle>\": "\
    "new parent \"<parent_handle>\", is the item's child."
  MAKE_SELF_PARENT_TEMPLATE =
    "Error in spec for item with handle \"<handle>\": "\
    "item cannot be its own parent (\"<parent_handle>\")."
  HANDLE_IN_USE_TEMPLATE =
    "Error re handle-change operation for \"<handle>\": "\
    "new handle \"<new_handle>\" is already in use."

  def invalid_parent_handle_msg(handle, parent_handle)
    result = INVALID_PARENT_HANDLE_TEMPLATE.sub(HANDLE_TAG, handle)
    result = result.sub(P_HANDLE_TAG, parent_handle)
    result
  end

  def recursive_child_parent_msg(handle, parent_handle)
    result = RECURSIVE_PARENT_HANDLE_TEMPLATE.sub(HANDLE_TAG, handle)
    result = result.sub(P_HANDLE_TAG, parent_handle)
    result
  end

  def request_to_make_self_parent_msg(handle, parent_handle)
    result = MAKE_SELF_PARENT_TEMPLATE.sub(HANDLE_TAG, handle)
    result = result.sub(P_HANDLE_TAG, parent_handle)
    result
  end

  def new_handle_in_use_msg(handle, new_handle)
    result = HANDLE_IN_USE_TEMPLATE.sub(HANDLE_TAG, handle)
    result = result.sub(N_HANDLE_TAG, new_handle)
    result
  end

  # Should proposed references to non-existent "STodoTarget"s be rejected?
  def reject_false_references
    answer = ENV[ST_REJECT_BADREFS]
$log.warn "[reject_false_references] ret: #{! answer.nil? && ! answer.empty?}"
    ! answer.nil? && ! answer.empty?
  end

  # Should proposed attachments referring to non-existent files be rejected?
  def reject_nonexistent_attachments
    answer = ENV[ST_REJECT_BADATTCHMTS]
$log.warn "[reject_nonexistent_attachments] ret: #{! answer.nil? && ! answer.empty?}"
    ! answer.nil? && ! answer.empty?
  end

end
