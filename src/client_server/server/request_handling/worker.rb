require 'publisher'
require 'stodo_services_constants'
require 'command_line_request'
require 'templatetargetbuilder'
require 'templateoptions'
require 'command_facilities'
require 'client_request_handler'

class Worker < Publisher
  include ClientRequestHandler, STodoServicesConstants, CommandFacilities

  public

  alias_method :delegate_request, :process_request

  private

#!!!rm:  attr_accessor :config

  def initialize(config)
    init_crh_attributes(config)
    super(SERVER_RESPONSE_CHANNEL)
  end

end
