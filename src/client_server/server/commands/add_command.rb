require 'work_command'
require 'stodo_target_constants'

#!!!!See NOTE in WorkCommand!!!
class AddCommand < WorkCommand
  include STodoTargetConstants

  private

  attr_accessor :target_factory_for
  attr_reader   :mailer

  ###  Initialization

  def initialize(config, manager)
    self.target_factory_for = STodoTargetFactory.new(config)
    @mailer = Mailer.new(config)
    super(config, manager)
  end

  private

  attr_accessor :database
  # The 'caller' of 'do_execute':
  attr_accessor :the_caller

  ### Implementation of inherited abstract methods

  def do_execute(the_caller)
    self.the_caller = the_caller
    self.database = the_caller.database
    spec = new_spec
    if ! spec.nil? then
      builder = target_factory_for[spec.type]
      target = new_stodo_target(builder, spec)
      store(target)
      add_parent(target)
      init_git(target)
      initiate(target)
    else
      self.execution_succeeded = false
      self.fail_msg = "Invalid spec [arguments: #{request.arguments}]"
    end
  end

  def new_spec
    result = nil
    # strip out the 'command: add'
    options = TemplateOptions.new(request.arguments[1 .. -1], true)
    spec = StubbedSpec.new(options)
    spec.database = the_caller.database
    if ! valid_type(spec.type) then
      $log.error("invalid stodo item type: #{spec.type}")
#!!!!Need to create and send an 'error' response to the client.
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

  def init_git(target)
    if target.commit then
      repo = config.stodo_git
      repo.update_item(target)
      repo.commit target.commit
    end
  end

  # After preparations, call 'target.initiate'.
  def initiate(target)
    email = Email.new(mailer)
    calendar = CalendarEntry.new @configuration
    target.add_notifier(email)
    target.initiate(calendar, the_caller)
  end

  # A new "STodoTarget' object of the type (class) specified by spec.type
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

#!!!!!remove:
  pre :req_set do ! self.request.nil? end
  def old_do_execute(the_caller)
    self.the_caller = the_caller
logf = File.new("/tmp/addcmd#{$$}", "w")
logf.puts("#{self.class} self: #{self}")
logf.flush
self.database = the_caller.database
    # strip out the 'command: add'
    opt_args = request.arguments[1 .. -1]
logf.puts("opt_args: #{opt_args}")
    options = TemplateOptions.new(opt_args, true)
logf.puts("options: #{options.inspect}")
logf.flush
    manager.target_builder.spec_collector = options
    manager.target_builder.set_create_mode
#!!!to-do: See 'add_new_targets' implementation and steal the
#!!!needed guts of it to put here, then delete this call:
    manager.add_new_targets
#!!!Might end with:
#database.store_target(new_target)
logf.puts("#{self.class} ended")
logf.flush
  end

end
