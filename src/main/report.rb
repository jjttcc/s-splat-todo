#!/usr/bin/env ruby
# Display a report of existing s*todo items.

require 'configuration'
require 'stodomanager'
require 'reportmanager'
require 'targetstateset'

class ReportUtil
  def self.proc_for_arg1 reporter
    result = nil
    states = requested_states
    if ARGV.length > 0 then
      case ARGV[0]
      when /^short/
        result = Proc.new {
          reporter.list_targets(true, ARGV[1..-1], states)
        }
      when /^sum/
        result = Proc.new {
          reporter.list_targets(false, ARGV[1..-1], states)
        }
      when /^com/
        result = Proc.new { reporter.report_complete(ARGV[1..-1], states) }
      when /^rem/
        case ARGV[0]
        when /rem.*all/ # all reminders
          result = Proc.new {
            reporter.report_reminders(all: true, handles: ARGV[1..-1],
                                     states: states)
          }
        when /rem.*h/   # only the 1st reminder, print handle instead of title
          result = Proc.new {
            reporter.report_reminders(all: false, handles: ARGV[1..-1],
                                     short: true, states: states)
          }
        else            # only the 1st reminder (with title)
          result = Proc.new {
            reporter.report_reminders(all: false, handles: ARGV[1..-1],
                                     states: states)
          }
        end
      when /^chi/
        result = Proc.new { reporter.report_targets_descendants(ARGV[1..-1]) }
      when /^due/
        result = Proc.new {
          reporter.report_due(ARGV[1..-1], states)
        }
      end
    end
    if result == nil then
      result = Proc.new { reporter.list_handles(states) }
    end
    result
  end

  def self.requested_states
    if ARGV.length > 0 then
      if ARGV[0] =~ /ign/ then
        result = TargetStateSet.new   # Report on all items.
      else
        active_states_only = false
        part2 = ARGV[0].split(/:/)[1]
        if part2 != nil && ! part2.empty? then
          components = part2.split(/,\s*/)
        else
          components = []
          # (No :<state> component and no handles -> only active states)
          active_states_only = ARGV.length == 1
        end
        # States for report on user-specified item.
        result = TargetStateSet.new(components)
        if active_states_only then result.remove_final end
      end
    else
      result = TargetStateSet.new
      # Default: report only on in-progress and suspended items
      result.remove_final
    end
    result
  end
end

config = Configuration.new
manager = STodoManager.new config
reporter = ReportManager.new manager
ReportUtil::proc_for_arg1(reporter).call
