require 'ruby_contracts'

# Abstraction for logic needed for a "service"
module Service
  include Contracts::DSL

  public

  #####  Access

  attr_reader :service_tag

  #####  Boolean queries

  # Is logging turned on?
  attr_reader :logging_on

  # Is verbose logging enabled?
  attr_accessor :verbose

  #####  State-changing operations

  # Ensure 'logging_on'.
  post :on do logging_on end
  def turn_on_logging
    @logging_on = true
  end

  # Ensure NOT 'logging_on'.
  post :off do ! logging_on end
  def turn_off_logging
    @logging_on = false
  end

  #####  Basic operations

  # Start the service.
  def execute(args = nil)
    prepare_for_main_loop(args)
    while continue_processing do
#!!!binding.irb
      pre_process(args)
      process(args)
      post_process(args)
    end
    main_loop_cleanup(args)
  rescue StandardError => e
    msg = "Unrecoverable error occurred for service '#{service_tag}':\n'#{e}'"
#    msg += " - stack:\n#{e.backtrace.join("\n")}"
    $log.error(msg)
    raise msg
  end

  protected

  ##### Implementation - utilities

  attr_reader :config, :error_log

=begin
#needed?:
  # (Redefined to additionally log the 'msg' if 'logging_on'.)
  def set_message(key, msg, expire_secs = nil, admin = false)
    super(key, msg, expire_secs, admin)
    if logging_on then
      log.send_message(tag: key, msg: msg)
    end
  end

  # If 'logging_on', log the specified set of messages.
  pre :log   do |log_attr| self.log != nil && self.log.is_a?(MessageLog) end
  pre :mhash do |mhash| mhash != nil && mhash.is_a?(Hash) end
  def log_messages(messages_hash)
    if logging_on then
      log.send_messages(messages_hash: messages_hash)
    end
  end

  # If 'logging_on' and 'verbose', log the specified set of messages.
  pre :log   do |log_attr| self.log != nil && self.log.is_a?(MessageLog) end
  pre :mhash do |mhash| mhash != nil && mhash.is_a?(Hash) end
  def log_verbose_messages(messages_hash)
    if verbose && logging_on then
      log.send_messages(messages_hash: messages_hash)
    end
  end

  # Number of kilobytes of RAM being used
  def mem_usage
    config.mem_usage
  end
=end

  # Perform any needed preparation before starting the main 'while' loop.
  # (To turn this into a [template-method-pattern] hook method, simply
  # redefine this method in the "descendant class" and call 'super(args)'
  # at the appropriate time - e.g.:
  #   do_stuff #...
  #   super(args)
  #   # [do_more_stuff #...]
  # )
  def prepare_for_main_loop(args)
  end

  ##### Hook methods

  def continue_processing
    true  # Redefine if needed.
  end

  # Perform any needed cleanup after ending the main 'while' loop.
  def main_loop_cleanup(args)
    # Null operation - Redefine if needed.
  end

  # Perform the main processing.
  def process(args = nil)
    # Null operation - Redefine if needed.
  end

  # Perform any needed pre-processing before 'process' is called.
  def pre_process(args = nil)
  end

  # Perform any needed post-processing after 'process' is called.
  def post_process(args = nil)
    # Null operation - Redefine if needed.
  end

end
