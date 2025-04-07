require 'ruby_contracts'
require 'report_request_handler'

class ReportCreationHandler < ReportRequestHandler
  include Contracts::DSL

  public

  def execute(log)
    log.set_object(report_specs.response_key, report)
  end

  private

  # Data gathered using specs via 'report_specs'
  pre  :has_key_list do
    report_specs[:key_list] != nil && ! report_specs[:key_list].empty? end
  post :resgood do |result| result != nil && result.is_a?(StatusReport) end
  def report
    contents = config.log_reader.contents_for(report_specs)
    result = config.status_report.new(contents)
    result
  rescue StandardError => e
    raise e
  end

end
