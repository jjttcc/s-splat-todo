# A set of "TargetState"s to be used, for example, to specify which states
# are to be included in a report.  When created without arguments (i.e.,
# TargetStateSet.new), the set will contain all four states.  To create a set
# of specific states, pass in to 'new' an array of strings, where each
# element of the array matches all or part of one or more state names.  All
# states for which a match is found will be included in the set.  For example:
# TargetStateSet.new(["inp", "susp"])
# to match the IN_PROGRESS and SUSPENDED states.
class TargetStateSet
  include TargetStateValues

  public

  attr_reader :states

  ###  Access

  # Does "self"'s set of states include the state of STodoTarget 't'?
  def include?(t)
    result = false
    if t.state != nil then
      result = states.include?(t.state.value)
    end
    result
  end

  # Does "self"'s set of states include one and only one state that matches
  # the string 's'?  If 'report_multiple' is true, log cases in which 's'
  # matches more than one state.
  def include_one_match?(s, report_multiple = false)
    count = 0
    matches = @cleaned_states.keys.grep(/#{s}/)
    count = matches.count
    if report_multiple && count > 1 then
      $log.warn %Q["#{s}" matches more than one state: ] +
        matches.join(', ')
    end
    result = count == 1
    result
  end

  # Does "self"'s set of states include any state that matches the string 's'?
  def include_any_match?(s)
    result = @cleaned_states.keys.grep(/#{s}/).count > 0
    result
  end

  #####  Measurement

  # Number of "TargetState"s in the set
  def count
    states.count
  end

  ###  Element change

  # Remove the "final" states - i.e., CANCELED and COMPLETED
  def remove_final
    @states.subtract([CANCELED, COMPLETED])
    @cleaned_states = cleaned_states
  end

  # Remove all states except for IN_PROGRESS.
  def inprog_only
    @states.subtract([SUSPENDED, CANCELED, COMPLETED])
    @cleaned_states = cleaned_states
  end

  private

  # results for parameter 'match_filters':
  #    nil           ->  Initialize as an empty set.
  #    <default>     ->  ["c", "u", "i"] - Results in a set of all states.
  #    [f1, f2, ...] ->  ["c", "u", "i"] - Results in a set of states that
  #                                        match the specified filter values.
  def initialize(match_filters = ["c", "u", "i"])
    if match_filters.nil? then
        @states = Set.new
    else
      all_sv = all_state_values
      #    if match_filters != nil && match_filters.length > 0 then
      if match_filters.length > 0 then
        @states = Set.new
        match_filters.each do |f|
          all_sv.grep(/#{f}/).each do |s|
            @states << s
          end
        end
      else
        @states = Set.new(all_sv)
      end
      @cleaned_states = cleaned_states
    end
  end

  # The contents of @states, but with non-word characters (such as '-')
  # removed
  def cleaned_states
#!!!!!after ensuring that this line does not change the output - remove it:
#!!!!!or, if it does change the output to an incorrect result, put it back in:
#@states.map {|s| s.gsub(/[\W_]/, "")}
    result = {}
    @states.each do |s|
      result[s.gsub(/[\W_]/, "")] = s
    end
    result
  end

end
