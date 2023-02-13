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

  # Digest the arguments (ARGV) and use them to produce the report.
  def self.execute reporter
    result = nil
    create_search_criteria
    if ARGV.length > 0 then
      case ARGV[0]
      when /^hand/
          result = Proc.new { reporter.list_handles(self.criteria) }
      when /^desc/
          result = Proc.new { reporter.show_description(self.criteria) }
      when /^tdesc/
          result = Proc.new { reporter.show_t_description(self.criteria) }
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
            reporter.report_reminders(all: true, criteria: criteria)
          }
        when /rem.*h/   # only the 1st reminder, print handle instead of title
          result = Proc.new {
            reporter.report_reminders(all: false, criteria: criteria,
                                      short: true)
          }
        else            # only the 1st reminder (with title)
          result = Proc.new {
            reporter.report_reminders(all: false, criteria: criteria)
          }
        end
      when /^chi/
        result = Proc.new {
          reporter.report_targets_descendants(criteria)
        }
      when /^par/
        result = Proc.new {
          reporter.report_parent(criteria)
        }
      when /^eman.*ch/
        result = Proc.new {
          reporter.report_emancipated_children(criteria)
        }
      when /^eman.*des/
        result = Proc.new {
          reporter.report_emancipated_descendants(criteria)
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

  TYPE_SPEC_SEP, KEY_VALUE_SEP, FIELD_SEP = '@', ':', ',\s*'
  STATES, PRIORITIES, TITLE_EXPRS, HANDLE_EXPRS, DESCR_EXPRS =
    'states', 'priorities', 'title_exprs', 'handle_exprs',
    'description_exprs'
  TOP_PRI, SECOND_PRI, THIRD_PRI, LAST_PRI = 1, 2, 3, 4
  ALL_PRIORITIES = [TOP_PRI, SECOND_PRI, THIRD_PRI, LAST_PRI]

  # Parse the specs implied by ARGV, create a resulting instance of
  # SearchCriteria, and initialize attribute 'criteria' to that instance.
  def self.create_search_criteria
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
            set_states(value)
          elsif PRIORITIES =~ /#{key}/ then
            set_priorities(value)
          elsif TITLE_EXPRS =~ /#{key}/ then
            set_title_exprs(value)
          elsif HANDLE_EXPRS =~ /#{key}/ then
            set_handle_exprs(value)
          elsif DESCR_EXPRS =~ /#{key}/ then
            set_description_exprs(value)
          else
            $stderr.puts "Warning: invalid type label: #{p}"
          end
        end
      end
    end
    if self.handles.empty? && self.states.nil? then
      set_states(nil)
    end
    build_criteria
  end

  # Set self.handles to the list 's'.
  def self.set_handles(hlist)
    self.handles = hlist
  end

  # Set self.states according to the specifications implied by 's'.
  # Note: 'stat:all' or 'stat:*' implies all states.
  def self.set_states(s)
    if s != nil then
      if s == "all" || s == "*" then
        self.states = TargetStateSet.new   # Report on all items.
      else
        active_states_only = false
        components = s.split(/#{FIELD_SEP}/)
        # States for report on user-specified item.
        self.states = TargetStateSet.new(components)
        if active_states_only then self.states.remove_final end
      end
    else
      self.states = TargetStateSet.new(nil)
    end
  end

  # Set self.priorities according to the specifications implied by 's'.
  def self.set_priorities(s)
    if s != nil then
      if s == "all" || s == "*" then
        self.priorities = ALL_PRIORITIES
      else
        self.priorities = []
        components = s.split(/#{FIELD_SEP}/)
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

  # Set self.title_exprs according to the specifications implied by 's'.
  def self.set_title_exprs(s)
    self.title_exprs = []
    if s != nil then
      components = s.split(/#{FIELD_SEP}/)
      components.each do |c|
        self.title_exprs << c
      end
    end
  end

  # Set self.handle_exprs according to the specifications implied by 's'.
  def self.set_handle_exprs(s)
    self.handle_exprs = []
    if s != nil then
      components = s.split(/#{FIELD_SEP}/)
      components.each do |c|
        self.handle_exprs << c
      end
    end
  end

  # Set self.description_exprs according to the specifications implied by 's'.
  def self.set_description_exprs(s)
    self.description_exprs = []
    if s != nil then
      components = s.split(/#{FIELD_SEP}/)
      components.each do |c|
        self.description_exprs << c
      end
    end
  end

  # Build self.criteria according to the current attribute values (states,
  # priorities, etc.)
  def self.build_criteria
    if self.states.nil? then
        self.states = TargetStateSet.new(nil)    # i.e., empty state set
    end
    self.criteria = SearchCriteria.new(self)
  end

  class << self
    attr_accessor :states, :priorities, :title_exprs,
      :handle_exprs, :description_exprs, :handles, :criteria
  end

end

config = Configuration.new
manager = STodoManager.new config
reporter = ReportManager.new manager
ReportUtil::execute(reporter).call
