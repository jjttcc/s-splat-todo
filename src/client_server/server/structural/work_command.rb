require 'ruby_contracts'

# Abstract ancestor - objects for carrying out work for "Worker"s
class WorkCommand
  include Contracts::DSL

  pre  :request_exists do |request| ! request.nil? end
  def execute(request)
  end

  private

  attr_accessor :manager

  def initialize(manager)
    self.manager = manager
  end

end
