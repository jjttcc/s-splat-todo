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
      when /^rem/
        case ARGV[0]
        when /rem.*all/ # all reminders
          result = Proc.new {
            reporter.report_reminders(all: true, handles: ARGV[1..-1])
          }
        when /rem.*h/   # only the 1st reminder, print handle instead of title
          result = Proc.new {
            reporter.report_reminders(all: false, handles: ARGV[1..-1],
                                     short: true)
          }
        else            # only the 1st reminder (with title)
          result = Proc.new {
            reporter.report_reminders(all: false, handles: ARGV[1..-1])
          }
        end
      when /^chi/
        result = Proc.new { reporter.report_targets_descendants(ARGV[1..-1]) }
      when /^due/
        result = Proc.new { reporter.report_due(ARGV[1..-1]) }
      end
    end
    if result == nil then
      result = Proc.new { reporter.list_handles }
    end
    result
  end
end

config = Configuration.new
manager = STodoManager.new config
reporter = ReportManager.new manager
ReportUtil::proc_for_arg1(reporter).call
