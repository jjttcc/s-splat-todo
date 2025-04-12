require 'report_request_handler'
require 'ruby_contracts'

class ReportInfoHandler < ReportRequestHandler
  include Contracts::DSL

  public

  def execute(log)
    log.set_object(report_specs.response_key, report)
  end

  private

  # Data gathered using specs via 'report_specs'
  pre  :has_key_list do
    report_specs[:key_list] != nil && ! report_specs[:key_list].empty? end
  post :resgood do |result| result != nil && result.is_a?(Hash) end
  def report
    result = config.log_reader.info_for(report_specs)
    result
  rescue StandardError => e
    raise e
  end

end
