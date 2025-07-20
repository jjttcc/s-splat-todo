require 'work_command'
require 'client_session'

class SessionRequestCommand < WorkCommand
  include CommandConstants, Contracts::DSL

  def do_execute(the_caller)
    session = ClientSession.new(new_session_id, request.user_id,
                                request.app_name)
    the_caller.send_session(session)
    self.execution_succeeded = true
  end

  def new_session_id
    "temporary-session-id-#{$$}"
  end

end
