require_relative 'mailer'

# Targets of one or more actions to be executed by the system
class ActionTargetManager
  attr_reader :targets, :mailer, :calendar

  public

  # Call `initiate' on each element of @targets.
  def perform_initial_processing
    targets.each do |t|
      t.initiate(self)
    end
  end

  private

  def initialize targets, config
    @targets = targets
    @mailer = Mailer.new config
  end

  ###  Basic operations

end
