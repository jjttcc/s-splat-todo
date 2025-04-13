require 'redis_status_report'
require 'report_specification'
require 'report_creation_handler'
require 'report_cleanup_handler'
require 'report_info_handler'
require 'oj_serializer'
require 'oj_de_serializer'
require 'system_tools'

class UtilityConfiguration
  include Contracts::DSL

  public

  #####  Access - classes or modules

  # StatusReport (descendant) instance of the appropriate type
  def self.status_report
    RedisStatusReport
  end

  post :has_data do |result| result != nil && result.method_defined?(:data) end
  def self.serializer
    OJSerializer
  end

  def self.de_serializer
    OJDeSerializer
  end

  def self.mem_usage
    SystemTools.rss_kbytes_used
  end

  #####  Access - objects

  begin

    @@report_handler = {
      ReportSpecification::CREATE_TYPE  => ReportCreationHandler,
      ReportSpecification::CLEANUP_TYPE => ReportCleanupHandler,
      ReportSpecification::INFO_TYPE    => ReportInfoHandler,
    }

    # ReportRequestHandler descendant object, according to 'specs.type'
    def self.report_handler_for(specs:, config:)
      result = nil
      type = @@report_handler[specs.type]
      if type != nil then
        result = type.new(specs: specs, config: config)
      end
      result
    end

  end
end
