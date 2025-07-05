require 'work_command'
require 'stodo_target_constants'

class AddCommand < WorkCommand
  include SpecTools, Contracts::DSL

  private

  attr_accessor :new_target_failure_reason
  attr_accessor :target_factory_for
  attr_reader   :mailer

  ###  Initialization

#!!!!!GOAL: get rid of need for 'manager' argument!!!!!
  def initialize(config, manager)
    self.target_factory_for = STodoTargetFactory.new(config)
    @mailer = Mailer.new(config)
    super(config, manager)
  end

  private

  # The 'caller' of 'do_execute':
  attr_accessor :the_caller

  ### Implementation of inherited abstract methods

  def do_execute(the_caller)
    self.the_caller = the_caller
    self.new_target_failure_reason = nil
    spec = new_spec
    if ! spec.nil? then
      if spec.handle == NONE_SPEC then
        self.new_target_failure_reason = ERROR_PREFACE +
          "#{NONE_SPEC} is not allowed as an item handle."
      else
        builder = target_factory_for[spec.type]
        target = new_stodo_target(builder, spec)
        if ! target.nil? then
          if add_parent(target) then
            store(target)
            git_commit(target)
            initiate(target)
            self.execution_succeeded = true
          end
        end
      end
      if ! new_target_failure_reason.nil? then
        self.fail_msg = new_target_failure_reason
      end
    else
      self.fail_msg = spec_error
    end
  end

  private   ### Implementation - helpers

  ERROR_PREFACE = "Problem with specification for item: "

  # Store 'target' in the database.
  def store(target)
    replace = true
#!!!!to-do: decide whether 'replace' logic should be specified by user!!
    database.store_target(target, replace)
  end

  # If 'target' has a parent_handle, retrieve the parent and notify it that
  # is has a new child.
  # If a problem is found with target.parent_handle, false is returned;
  # otherwise, true is returned.
  def add_parent(target)
    result = true
    if ! target.parent_handle.nil? then
      p = database.target_for(target.parent_handle)
      if p then
        p.add_child target
      else
        result = false
        self.new_target_failure_reason = ERROR_PREFACE +
        "parent handle invalid or parent does not exist " +
        "(#{target.parent_handle}) for item #{target.handle}"
        $log.warn new_target_failure_reason
      end
    end
    result
  end

  # After preparations, call 'target.initiate'.
  def initiate(target)
    email = Email.new(mailer)
    calendar = CalendarEntry.new @configuration
    target.add_notifier(email)
    target.initiate(calendar, the_caller)
  end

  # A new "STodoTarget' object of the type (class) specified by spec.type
  # If there is a problem with the specification (spec), nil is returned
  # and 'new_target_failure_reason' will contain an explanation of the
  # of the problem.
  def new_stodo_target(builder, spec)
    result = nil
    t = builder.call(spec)
    if t != nil && t.valid? then
      result = t
    elsif t != nil then
      self.new_target_failure_reason = ERROR_PREFACE +
        "#{t.handle} is not valid"
      if ! t.invalidity_reason.nil? then
        self.new_target_failure_reason =
          "#{self.new_target_failure_reason}: #{t.invalidity_reason}"
      end
      $log.warn self.new_target_failure_reason
    else
      self.new_target_failure_reason =
        "#{ERROR_PREFACE} (reason unspecified)"
    end
    result
  end

end
