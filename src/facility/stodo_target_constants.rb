# Constants for STodoTarget descendant types and aliases
module STodoTargetConstants

  public

  # types:
  TASK, APPOINTMENT, NOTE, PROJECT = 'task', 'appointment', 'note', 'project'
  # aliases:
  TASK_ALIAS1, APPOINTMENT_ALIAS1, APPOINTMENT_ALIAS2, NOTE_ALIAS1,
    NOTE_ALIAS2 = 'action', 'meeting', 'event', 'memorandum', 'memo'

  @@stodo_target_types = {
    TASK                => true,
    APPOINTMENT         => true,
    NOTE                => true,
    PROJECT             => true,
    TASK_ALIAS1         => true,
    APPOINTMENT_ALIAS1  => true,
    APPOINTMENT_ALIAS2  => true,
    NOTE_ALIAS1         => true,
    NOTE_ALIAS2         => true,
  }

  def valid_type(t)
    @@stodo_target_types[t]
  end

end
