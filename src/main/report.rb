#!/usr/bin/env ruby
# Display a report of existing s*todo items.

require 'configuration'
require 'stodomanager'
require 'reportmanager'

class ReportUtil
  def self.proc_for_arg1 reporter
    result = nil
    if ARGV.length > 0 then
      case ARGV[0]
      when /^short/
        result = Proc.new { reporter.list_targets(true, ARGV[1..-1]) }
      when /^sum/
        result = Proc.new { reporter.list_targets(false, ARGV[1..-1]) }
      when /^com/
        result = Proc.new { reporter.report_complete(ARGV[1..-1]) }
      when /^chil/
        result = Proc.new {
          reporter.report_targets_descendants(ARGV[1..-1])
        }
      end
    else
      result = Proc.new { reporter.list_handles }
    end
    result
  end
end

config = Configuration.new
manager = STodoManager.new config
reporter = ReportManager.new manager
ReportUtil::proc_for_arg1(reporter).call
