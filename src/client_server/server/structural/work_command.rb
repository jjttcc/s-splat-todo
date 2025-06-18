require 'ruby_contracts'
require 'errortools'

# Abstract ancestor - objects for carrying out work for "Worker"s
class WorkCommand
  include Contracts::DSL, ErrorTools

  public

  attr_accessor :client_session, :execution_succeeded, :fail_msg

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
    self.execution_succeeded = true
    self.fail_msg = ""
    self.database = the_caller.database
    do_execute(the_caller)
  end

  private

  # Abstract method
  pre  :request_set do ! self.request.nil? end
  pre  :start_with_success do execution_succeeded end
  pre  :database do ! self.database.nil? end
  def do_execute(the_caller)
    # descendant should set 'execution_succeeded' to false if it failed.
  end

  attr_accessor :request, :database

  attr_accessor :manager, :config

#!!!!!GOAL: get rid of need for 'manager' argument!!!!!
  def initialize(config = nil, manager)
    self.manager = manager
    if ! config.nil? then
      self.config = config
    end
  end

  private   ### Implementation - utilities for descendants

  # If 'target.commit' is not empty, do a "git commit" on 'target', with
  # 'got.commit' as the commit message.
  def git_commit(target)
    if ! target.commit.nil? && ! target.commit.empty? then
      repo = config.stodo_git
      repo.update_item(target)
      repo.commit target.commit
    end
  end

end
