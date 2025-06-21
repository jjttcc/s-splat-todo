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
    @remaining_args = nil
    @recursive = false
    @force = false
    @command, @arg1, @arg2 =
      request.command, request.arguments[1], request.arguments[2]
    if request.arguments.count > 3 then
      process_remaining_arguments
    end
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

  # Convenience queries for 'do_execute':
  attr_reader   :command, :arg1, :arg2
  # Array: args remaining beyond arg1 and arg2, if any:
  attr_reader   :remaining_args
  # Git-comment message extracted from 'remaining_args':
  attr_reader   :commit_msg
  # Has the client requested that the operation be recursive?
  attr_reader   :recursive
  # Has the client requested that an attempt be made to force the operation
  # to be carried out if a "problem" is encountered?
  attr_reader   :force

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

  OPT_CHAR      = '-'
  GIT_MSG_OPT   = '-m'
  RECURSIVE_OPT = '-r'
  FORCE_OPT     = '-f'

  # If 'target.commit' is not empty, do a "git commit" on 'target', with
  # 'got.commit' as the commit message.
  def git_commit(target)
    if ! commit_msg.nil? && ! commit_msg.empty?  then
      if target.commit.nil? || target.commit.empty? then
        target.commit = commit_msg
      end
    end
    if ! target.commit.nil? && ! target.commit.empty? then
      repo = config.stodo_git
#!!!!Is 'update_item' always the right call here?
      repo.update_item(target)
      repo.commit target.commit
    end
  end

  # Process 'remaining_args' into named options/arguments.
  post :remaining_args do
    ! self.remaining_args.nil? && self.remaining_args.count > 0
  end
  def process_remaining_arguments
    if ! arg2.nil? then
      if arg2[0] == OPT_CHAR then
        @remaining_args = request.arguments[2 .. -1]
      else
        @remaining_args = request.arguments[3 .. -1]
      end
      i = 0
      while i < remaining_args.count do
        if remaining_args[i][0] == OPT_CHAR then
          next_arg = remaining_args[i+1]
          case remaining_args[i]
          when GIT_MSG_OPT
            if ! next_arg.nil? then
              @commit_msg = next_arg
              i = i + 1
            end
          when RECURSIVE_OPT
            @recursive = true
          when FORCE_OPT
            @force = true
          else
          end
        end
        i = i + 1
      end
    else
      @remaining_args = []
    end
  end

end
