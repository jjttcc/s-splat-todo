require 'ruby_contracts'

# Request objects whose structure mimic the 'stodo' command line
# !!!This might need a name change to something like: ClientRequest.
class CommandLineRequest
  include Contracts::DSL

  public

  attr_reader   :command, :arguments
  attr_accessor :user_id, :app_name, :session_id

  pre  :not_nil do |c| ! c.nil? end
  pre  :invariant do invariant end
  post :command_not_nil do ! self.command.nil? end
  post :invariant do invariant end
  def command=(c)
    @command = c
  end

  pre  :not_nil do |args| ! args.nil? end
  pre  :args_array do |args| args.is_a?(Array) end
  pre  :invariant do invariant end
  post :arguments_not_nil do ! self.arguments.nil? end
  post :invariant do invariant end
  def arguments=(args)
    @arguments = args
  end

  private

  post :invariant do invariant end
  def initialize(user_id, app_name)
    @command = nil
    @arguments = []
    self.user_id = user_id
    self.app_name = app_name
  end

  ### Invariant

  def invariant
    ! arguments.nil? && implies(arguments.count > 0,
                                ! command.nil? && arguments[0] == command)
  end

end
