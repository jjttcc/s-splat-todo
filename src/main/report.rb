#!/usr/bin/env ruby
# Display a report of existing s*todo items.

require 'errortools'
require 'configuration'
require 'stodomanager'
require 'reportmanager'
require 'targetstateset'
require 'searchcriteria'

class ReportUtil
  public

  def self.new_proc_for_arg1 reporter
    result = nil
    if ARGV.length > 0 then
      case ARGV[0]
#!!!!! feed ARGV[1..-1] to a new class for parsing: SearchCriteria
      when /^short/
        result = Proc.new {
          reporter.list_targets(true, ARGV[1..-1])
        }
      when /^sum/
        result = Proc.new {
          reporter.list_targets(false, ARGV[1..-1])
        }
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
        result = Proc.new {
          reporter.report_due(ARGV[1..-1])
        }
      end
    end
    if result == nil then
      result = Proc.new { reporter.list_handles() }
    end
    result
  end

  # Digest the arguments (ARGV) and use them to produce the report.
  def self.execute reporter
    result = nil
    create_search_criteria
#!!!$stderr.puts "arg0: #{ARGV[0]}"
    if ARGV.length > 0 then
      case ARGV[0]
      when /^hand/
          result = Proc.new { reporter.list_handles(self.criteria) }
      when /^short/
        result = Proc.new {
          reporter.list_targets(true, self.criteria)
        }
      when /^sum/
        result = Proc.new {
          reporter.list_targets(false, self.criteria)
        }
      when /^com/
        result = Proc.new {
          reporter.report_complete(self.criteria)
        }
      when /^rem/
        case ARGV[0]
        when /rem.*all/ # all reminders
          result = Proc.new {
            reporter.report_reminders(all: true, handles: criteria.handles,
                                     states: criteria.states)
          }
        when /rem.*h/   # only the 1st reminder, print handle instead of title
          result = Proc.new {
            reporter.report_reminders(all: false, handles: criteria.handles,
                                     short: true, states: criteria.states)
          }
        else            # only the 1st reminder (with title)
          result = Proc.new {
            reporter.report_reminders(all: false, handles: criteria.handles,
                                     states: criteria.states)
          }
        end
      when /^chi/
        result = Proc.new {
          reporter.report_targets_descendants(criteria)
        }
      when /^due/
        result = Proc.new {
          reporter.report_due(criteria)
        }
      end
    end
    if result == nil then
      result = Proc.new { reporter.list_handles(self.criteria) }
    end
    result
  end

  private

  TYPE_SPEC_SEP, KEY_VALUE_SEP = '@', ':'
  STATES, PRIORITIES, TITLE_EXPRS, HANDLE_EXPRS =
    'states', 'priorities', 'title_exprs', 'handle_exprs'
  TOP_PRI, SECOND_PRI, THIRD_PRI, LAST_PRI = 1, 2, 3, 4
  ALL_PRIORITIES = [TOP_PRI, SECOND_PRI, THIRD_PRI, LAST_PRI]

  # Parse the specs implied by ARGV, create a resulting instance of
  # SearchCriteria, and initialize attribute 'criteria' to that instance.
  def self.create_search_criteria
    if self.type_specs == nil then
      self.type_specs = {}
      self.handles = []
      if ARGV.length > 1 then
        parts = ARGV[1].split(TYPE_SPEC_SEP)
        parts.each do |p|
          key, value = p.split(KEY_VALUE_SEP)
          if value.nil? then
            # ARGV[1] contains no KEY_VALUE_SEP - assume list of handles.
            set_handles(ARGV[1..-1])
          else
            if STATES =~ /#{key}/ then
#!!!$stderr.puts "ss-value"
              set_states(value)
            elsif PRIORITIES =~ /#{key}/ then
              set_priorities(value)
            elsif TITLE_EXPRS =~ /#{key}/ then
              set_title_exprs(value)
            elsif HANDLE_EXPRS =~ /#{key}/ then
              set_handle_exprs(value)
            else
#!!!!I think we need to set handles here!!!! - maybe not!!!
              $stderr.puts "Warning: invalid type label: #{p}"
            end
          end
        end
      end
    end
    if self.handles.empty? && self.states.nil? then
#!!!$stderr.puts "ss-nil"
      set_states(nil)
    end
    build_criteria
  end

  def self.set_handles(hlist)
#!!!$stderr.puts "#{__method__}: hlist: #{hlist.inspect}"
    self.handles = hlist
  end

  #!!!!to-do: document this method
  #!!!!to-do: document that 'stat:all' or 'stat:*' means all states.
  def self.set_states(s)
    if s != nil then
      if s == "all" || s == "*" then
        self.states = TargetStateSet.new   # Report on all items.
      else
        active_states_only = false
        components = s.split(/,\s*/)
        # States for report on user-specified item.
        self.states = TargetStateSet.new(components)
#!!!!!???!:
        if active_states_only then self.states.remove_final end
      end
    else
#!!!!changed[check]:      self.states = TargetStateSet.new
#!!!!to:
      self.states = TargetStateSet.new(nil)
#!!!!removed:      # Default: report only on in-progress and suspended items
#!!!!removed[check]:      self.states.remove_final
    end
  end

  #!!!!to-do: document this method
  def self.set_priorities(s)
    if s != nil then
      if s == "all" || s == "*" then
        self.priorities = ALL_PRIORITIES
      else
        self.priorities = []
        components = s.split(/,\s*/)
        components.each do |c|
          p = c
          if p.to_i > 0 then
            self.priorities << p
          end
        end
      end
    else
      self.priorities = []  # i.e., report on all priorities.
    end
  end

  def self.set_title_exprs(s)
  end

  def self.set_handle_exprs(s)
  end

  def self.build_criteria
    if self.states.nil? then
        self.states = TargetStateSet.new(nil)    # i.e., empty state set
    end
    self.criteria = SearchCriteria.new(self)
  end

  def self.old___requested_states
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

  class << self
    attr_accessor :type_specs, :states, :priorities, :title_exprs,
      :handle_exprs, :handles, :criteria
  end

end

config = Configuration.new
manager = STodoManager.new config
reporter = ReportManager.new manager
ReportUtil::execute(reporter).call
