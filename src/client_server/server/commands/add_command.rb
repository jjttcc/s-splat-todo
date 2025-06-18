require 'work_command'
require 'stodo_target_constants'

class AddCommand < WorkCommand
  include STodoTargetConstants

  private

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
  attr_reader   :spec_error

  ### Implementation of inherited abstract methods

  def do_execute(the_caller)
    self.the_caller = the_caller
    spec = new_spec
    if ! spec.nil? then
      builder = target_factory_for[spec.type]
      target = new_stodo_target(builder, spec)
      store(target)
      add_parent(target)
      git_commit(target)
      initiate(target)
    else
      self.execution_succeeded = false
      self.fail_msg = spec_error
    end
  end

  def new_spec
    result = nil
    # strip out the 'command: add'
    options = TemplateOptions.new(request.arguments[1 .. -1], true)
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

  # Store 'target' in the database.
  def store(target)
    replace = false
#!!!!to-do: decide whether 'replace' logic should be specified by user!!
    database.store_target(target, replace)
  end

  # If 'target' has a parent_handle, retrieve the parent and notify it that
  # is has a new child.
#!!!This method might want to be moved to an ancestor class or utility
#!!!module.
  def add_parent(target)
    if ! target.parent_handle.nil? then
      p = database.target_for(target.parent_handle)
      if p then
        p.add_child target
      else
        $log.warn "invalid parent handle (#{target.parent_handle}) for" \
          "item #{target.handle} - changing to 'no-parent'"
          target.parent_handle = nil
      end
    end
  end

  # After preparations, call 'target.initiate'.
#!!!This method might want to be moved to an ancestor class or utility
#!!!module.
  def initiate(target)
    email = Email.new(mailer)
    calendar = CalendarEntry.new @configuration
    target.add_notifier(email)
    target.initiate(calendar, the_caller)
  end

  # A new "STodoTarget' object of the type (class) specified by spec.type
#!!!This method might want to be moved to an ancestor class or utility
#!!!module.
  def new_stodo_target(builder, spec)
    t = builder.call(spec)
    if t != nil && t.valid? then
      result = t
    elsif t != nil then
      msg = "#{t.handle} is not valid"
      if ! t.invalidity_reason.nil? then
        msg = "#{msg}: #{t.invalidity_reason}"
      end
      $log.warn msg
    end
  end

end
