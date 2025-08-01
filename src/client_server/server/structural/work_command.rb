require 'ruby_contracts'
require 'errortools'

# Abstract ancestor - objects for carrying out work for "Worker"s
class WorkCommand
  include Contracts::DSL, ErrorTools, STodoTargetConstants

  public

  attr_accessor :client_session, :execution_succeeded
  # Client-response string - data, or error message on failure
  attr_accessor :response

  pre  :caller_exists do |callr| ! callr.nil? end
  pre  :request_exists do |callr| ! callr.request.nil? end
  post :request_set do |res, callr|
    ! self.request.nil? && self.request == callr.request
  end
  def execute(the_caller)
    self.request = the_caller.request
    @command = request.command
    args = request.arguments[1..-1] || []
    process_arguments(args)
    self.execution_succeeded = false
    self.response = ""
    self.database = the_caller.database
    database.set_appname_and_user(request.app_name, request.user_id)
    do_execute(the_caller)
  end

  private

  attr_reader   :spec_error, :positional_args

  # Abstract method
  pre  :request_set do ! self.request.nil? end
  pre  :start_with_failure do ! execution_succeeded end
  pre  :database do ! self.database.nil? end
  def do_execute(the_caller)
    # descendant should set 'execution_succeeded' to true if it succeeds.
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
  # Has the client requested a short format for reports?
  attr_reader   :short_format

  attr_accessor :request, :database

  attr_accessor :config

  def initialize(config = nil)
    if ! config.nil? then
      self.config = config
    end
  end

  private   ### Implementation - utilities for descendants

  OPT_CHAR      = '-'
  GIT_MSG_OPT   = '-m'
  RECURSIVE_OPT = '-r'
  FORCE_OPT     = '-f'
  SHORT_OPT     = '-s'

  # If a "git commit" is pending, obtain the commit message and use the
  # configured STodoGit object to "add" 'target' to the git repo and commit
  # it.
  # NOTE: This method has been converted into a "null op" to prevent the
  # 'git-lock' problems that occur due to multiple processes accessing the
  # same git repository at the same time. This will likely remain as a
  # null-op until the problem is solved or use of git for versioning has
  # been removed.
  def git_commit(target)
    if false then
    if ! commit_msg.nil? && ! commit_msg.empty?  then
      if target.commit.nil? || target.commit.empty? then
        target.commit = commit_msg
      end
    end
    if ! target.commit.nil? && ! target.commit.empty? then
      repo = config.stodo_git
      repo.update_item(target)
      repo.commit target.commit
    end
    end
  end

  def process_arguments(args)
    # Initialize
    @recursive = false
    @force = false
    @commit_msg = nil
    @short_format = false
    # Separate options from positional args
    @positional_args = []
    i = 0
    while i < args.count
      arg = args[i]
      if arg.start_with?(OPT_CHAR)
        case arg
        when RECURSIVE_OPT
          @recursive = true
        when FORCE_OPT
          @force = true
        when SHORT_OPT
          @short_format = true
        when GIT_MSG_OPT
          if (i + 1) < args.count
            @commit_msg = args[i+1]
            i += 1 # Skip next arg
          end
        else
          # Unknown option, treat as positional
          @positional_args << arg
        end
      else
        @positional_args << arg
      end
      i += 1
    end
    # Now, assign positional args to @arg1, @arg2, etc.
    @arg1 = positional_args[0]
    @arg2 = positional_args[1]
    if positional_args.count > 2
      @remaining_args = positional_args[2..-1]
    else
      @remaining_args = []
    end
  end

  # A new 'StubbedSpec' object constructed from 'args'
  def new_spec(args = positional_args)
    result = nil
    # strip out the 'command: add'
    options = TemplateOptions.new(args, true)
    spec = StubbedSpec.new(options)
    spec.database = database
    if ! valid_type(spec.type) then
      @spec_error = "invalid stodo item type: #{spec.type}"
      $log.error(spec_error)
    else
      result = spec
    end
    result
  end

end
