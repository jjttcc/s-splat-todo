# Targets of one or more actions to be executed by the system
class ActionTargetManager
  attr_reader :targets

  public

  # Register `target' for processing.
  def register target
puts "#{self} registering:"; p target
    @targets << target
    setup target
    perform_registration_actions target
  end

  private

  def initialize
    @targets = []
    @registration_actions = []
    @scheduled_actions = []
  end

  # xxx
  def setup t
  end

  # Perform all actions on target `t' that are to be executed upon t's
  # registration.
  def perform_registration_actions t
  end
end
