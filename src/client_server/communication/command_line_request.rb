require 'ruby_contracts'

# Request objects whose structure mimic the 'stodo' command line
class CommandLineRequest
  include Contracts::DSL

  public

  attr_reader :command, :arguments

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
  def initialize
    @command = nil
    @arguments = []
  end

  ### Invariant

  def invariant
    ! arguments.nil? && implies(arguments.count > 0,
                                ! command.nil? && arguments[0] == command)
  end

end
