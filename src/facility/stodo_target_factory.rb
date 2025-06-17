require 'stodo_target_constants'
require 'ruby_contracts'

# Dispensers of STodoTarget ancestor "builders"
class STodoTargetFactory
  include STodoTargetConstants
  include Contracts::DSL

  public

  # The "builder" (lambda) for STodoTarget type 'st_type'
  pre  :not_nil do |st_type| ! st_type.nil? end
  def [](st_type)
    builders[st_type]
  end

  private

  # Hash table of STodoTarget "builders":
  attr_accessor :builders

  # Initialize using 'config' (a Configuration instance).
  def initialize(config)
    cc_factory = config.stodo_target_child_container_factory
    self.builders = {
      PROJECT     => lambda do |spec| Project.new(spec, cc_factory.call) end,
      TASK_ALIAS1 => lambda do |spec|
        Task.new(spec, cc_factory.call) end,
      NOTE        => lambda do |spec| Memorandum.new(spec, cc_factory.call) end,
      APPOINTMENT => lambda do |spec| ScheduledEvent.new(spec,
                                                         cc_factory.call) end,
    }
    # Define "type" aliases.
    self.builders[TASK] = self.builders[TASK_ALIAS1]
    self.builders[NOTE_ALIAS1] = self.builders[NOTE]
    self.builders[NOTE_ALIAS2] = self.builders[NOTE]
    self.builders[APPOINTMENT_ALIAS1] = self.builders[APPOINTMENT]
    self.builders[APPOINTMENT_ALIAS2] = self.builders[APPOINTMENT]
  end

end
