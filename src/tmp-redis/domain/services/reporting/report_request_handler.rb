require 'ruby_contracts'

# Objects that execute report-related requests
class ReportRequestHandler
  include Contracts::DSL

  public

  #####  Access

  attr_reader :report_specs, :config

  pre :specs do self.report_specs != nil end
  pre :log do |log| log != nil && log.respond_to?(:set_object) end
  def execute(log)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  protected

  pre  :specs do |hash|
    hash[:specs] != nil && hash[:specs].is_a?(ReportSpecification) end
  pre  :config do |hash| hash[:config] != nil end
  post :attrs_set do self.report_specs != nil && self.config != nil end
  def initialize(specs:, config:)
    @report_specs = specs
    @config = config
  end

end
