require 'ruby_contracts'
require 'errortools'

# Abstract ancestor - objects for carrying out work for "Worker"s
class WorkCommand
  include Contracts::DSL, ErrorTools

  public

  attr_accessor :client_session

#!!!!NOTE: It will probably be better/simpler in most (all?) cases
#!!!!for the Commands to simply retrieve the object to be modified
#!!!!or used from the database and modify/query it directly, rather
#!!!!than using the manager, TargetBuilder, etc. to do it.
#!!!!This architecture might also make it easier to implement an REST API
#!!!!for the web implementation - i.e., using these commands.
  pre  :caller_exists do |callr| ! callr.nil? end
  pre  :request_exists do |callr| ! callr.request.nil? end
  post :request_set do |res, callr|
    ! self.request.nil? && self.request == callr.request
  end
  def execute(the_caller)
    self.request = the_caller.request
    do_execute(the_caller)
  end

  private

  # Abstract method
  pre  :request_set do ! self.request.nil? end
  def do_execute(the_caller)
  end

  attr_accessor :request

  attr_accessor :manager, :config

  def initialize(config = nil, manager)
    self.manager = manager
    if ! config.nil? then
      self.config = config
    end
  end

end
