require 'ruby_contracts'

# Request objects whose structure mimic the 'stodo' command line
class CommandLineRequest
  include Contracts::DSL

  public

  attr_reader   :command, :arguments
  attr_accessor :user_id, :app_name, :session_id

  pre  :args do ! arguments.nil? end
  def command=(c)
    @command = c
  end

  pre  :not_nil do |args| ! args.nil? end
  pre  :args_array do |args| args.is_a?(Array) end
  post :arguments_not_nil do ! self.arguments.nil? end
  def arguments=(args)
    @arguments = args
  end

  private

  def initialize(user_id, app_name)
    @command = nil
    @arguments = []
    self.user_id = user_id
    self.app_name = app_name
  end

end
