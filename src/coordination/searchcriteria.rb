require 'errortools'
require 'preconditionerror'
require 'postconditionerror'
require 'timetools'
require 'awesome_print'

# An instance of this class specifies a set of criteria - statuses and/or
# priorities and/or regexes for matching titles and/or etc.
class SearchCriteria
  include ErrorTools

  public

  #####  Access

  attr_reader :states, :priorities, :title_exprs, :handle_exprs, :handles

  #####  Status report

  # Should only the 'handles' list be used - i.e., other specs are empty?
  def handles_only?
    assert_invariant {invariant}
#    self.handles.count > 0 && self.states.count == 0 &&
#      self.priorities.count == 0 && self.title_exprs.count == 0 &&
#      self.handle_exprs.count == 0
#!!!$stderr.puts "handles.count: #{handles.count}"
#!!!$stderr.puts "states.count: #{states.count}"
#!!!$stderr.puts "priorities.count: #{priorities.count}"
#!!!$stderr.puts "title_exprs.count: #{title_exprs.count}"
#!!!$stderr.puts "handle_exprs.count: #{handle_exprs.count}"
    handles.count > 0 && states.count == 0 &&
      priorities.count == 0 && title_exprs.count == 0 &&
      handle_exprs.count == 0
  end

  # Are all criteria empty/unspecified?
  def null_criteria?
    handles.count == 0 && states.count == 0 &&
      priorities.count == 0 && title_exprs.count == 0 &&
      handle_exprs.count == 0
  end

  private

  attr_writer :states, :priorities, :title_exprs, :handle_exprs, :handles

  # precondition: datetime != nil
  def initialize(criteria)
    assert_precondition {criteria != nil && criteria.states != nil}
    self.states = criteria.states
    self.title_exprs = (criteria.title_exprs.nil?)? []: criteria.title_exprs
    self.handle_exprs = (criteria.handle_exprs.nil?)? []: criteria.handle_exprs
#!!!$stderr.puts "#{__method__}: criteria.handles: #{criteria.handles.inspect}"
    self.handles = (criteria.handles.nil?)? []: criteria.handles
#!!!$stderr.puts "#{__method__}: self.handles: #{self.handles.inspect}"
    self.priorities = []
    if criteria.priorities != nil then
      criteria.priorities.each do |p|
        self.priorities << p.to_s
      end
    end
#!!!$stderr.puts "self.handles: #{self.handles}"
#!!!$stderr.puts "self.states: #{self.states}"
#!!!$stderr.puts "self.priorities: #{self.priorities}"
#!!!$stderr.puts "self.title_exprs: #{self.title_exprs}"
#!!!$stderr.puts "self.handle_exprs: #{self.handle_exprs}"
    assert_invariant {invariant}
  end

  ### class invariant

  def invariant
    ! (self.handles.nil? || self.states.nil? || self.priorities.nil? ||
       self.title_exprs.nil? || self.handle_exprs.nil?)
  end

end
