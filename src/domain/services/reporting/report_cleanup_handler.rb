require 'ruby_contracts'
require 'report_request_handler'

class ReportCleanupHandler < ReportRequestHandler
  include Contracts::DSL

  public

  def execute(log)
    config.log_reader.trim_contents(report_specs)
  end

end
