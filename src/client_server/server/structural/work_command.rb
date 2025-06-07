# Abstract ancestor - objects for carrying out work for "Worker"s
class WorkCommand

  def execute
  end

  private

  attr_accessor :client_request, :manager

  def initialize(request, manager)
    self.client_request = request
    self.manager = manager
  end

end
