require 'ruby_contracts'
require 'errortools'
require 'preconditionerror'
require 'postconditionerror'
require 'timetools'
require 'awesome_print'

# An instance of this class specifies a set of criteria - statuses and/or
# priorities and/or regexes for matching titles and/or etc.
class SearchCriteria
  include ErrorTools, Contracts::DSL

  public

  #####  Access

  attr_reader :states, :priorities, :types, :title_exprs, :handle_exprs,
    :description_exprs, :handles

  #####  Status report

  # Should only the 'handles' list be used - i.e., other specs are empty?
  def handles_only?
    assert_invariant {invariant}
    handles.count > 0 && states.count == 0 && types.count == 0 &&
      priorities.count == 0 && title_exprs.count == 0 &&
      handle_exprs.count == 0 && description_exprs.count == 0
  end

  # Are all criteria empty/unspecified?
  def null_criteria?
    handles.count == 0 && states.count == 0 && types.count == 0 &&
      priorities.count == 0 && title_exprs.count == 0 &&
      handle_exprs.count == 0 && description_exprs.count == 0
  end

  # Are one or more priorities specified?
  def has_priorities?
    priorities.count > 0
  end

  # Are one or more states specified?
  def has_states?
    states.count > 0
  end

  # Are one or more states specified?
  def has_types?
    types.count > 0
  end

  # Are one or more title expressions specified?
  def has_title_exprs?
    title_exprs.count > 0
  end

  # Are one or more handle expressions specified?
  def has_handle_exprs?
    handle_exprs.count > 0
  end

  # Are one or more description expressions specified?
  def has_description_exprs?
    description_exprs.count > 0
  end

  private

  attr_writer :states, :types, :priorities, :title_exprs, :handle_exprs,
    :description_exprs, :handles

  # precondition: datetime != nil
  pre 'valid arg' do |criteria| criteria != nil && criteria.states != nil end
  def initialize(criteria)
    self.states = criteria.states
    self.title_exprs = (criteria.title_exprs.nil?)? []: criteria.title_exprs
    self.handle_exprs = (criteria.handle_exprs.nil?)? []: criteria.handle_exprs
    self.description_exprs =
      (criteria.description_exprs.nil?)? []: criteria.description_exprs
    self.handles = (criteria.handles.nil?)? []: criteria.handles
    if criteria.types.nil? then
      self.types = []
    else
      self.types = criteria.types
    end
    self.priorities = []
    if criteria.priorities != nil then
      criteria.priorities.each do |p|
        self.priorities << p.to_s
      end
    end
    assert_invariant {invariant}
  end

  ### class invariant

  def invariant
    ! (self.handles.nil? || self.states.nil? || self.types.nil? ||
       self.priorities.nil? || self.title_exprs.nil? ||
       self.handle_exprs.nil? || self.description_exprs.nil?)
  end

end
