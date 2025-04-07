require 'util'
require 'report_component'

# Objects that contain a set of reports (or "ReportComponent"s), each of
# which contains one or more keyed messages, on a specific "topic" (e.g.,
# a particular service)
class TopicReport
  include Contracts::DSL, Util, Enumerable

  public

  #####  Access

  # topic label (or "handle")
  def label
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  alias_method :handle, :label

  # Date/time of the earliest report
  post :nil_if_empty do |res| implies(empty?, res.nil?) end
  def start_date_time
    result = nil
    if ! empty? then
      result = first.datetime
    end
    result
  end

  # Date/time of the latest report
  post :nil_if_empty do |res| implies(empty?, res.nil?) end
  def end_date_time
    result = nil
    if ! empty? then
      result = last.datetime
    end
    result
  end

  # First report component (chronologically)
  pre  :not_empty do count > 0 end
  post :component do |reslt| reslt != nil && reslt.is_a?(ReportComponent) end
  def first
    self[0]
  end

  # Last report component (chronologically)
  pre  :not_empty do count > 0 end
  post :component do |reslt| reslt != nil && reslt.is_a?(ReportComponent) end
  def last
    self[-1]
  end

  pre  :not_empty do count > 0 end
  pre  :in_range do |i| i == -1 || (i >= 0 && i < count) end
  post :component do |res| res != nil && res.is_a?(ReportComponent) end
  def [](index)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # All components whose timestamps are >= 'start_time' and <= 'end_time'
  pre  :times_exist do |st, et| st != nil && et != nil end
  pre  :have_ge do |st, et| st.respond_to?(">=") && et.respond_to?(">=") end
  pre  :have_lt do |st, et| st.respond_to?("<") && et.respond_to?("<") end
  post :result do |result| result != nil && result.is_a?(Enumerable) end
  def components_in_range(start_time, end_time)
    result = []
    ix_range = 0 .. self.count - 1
    # Find the earliest component c such that c.datetime >= 'start_time':
    start_i = ix_range.bsearch do |i|
      self[i].datetime >= start_time
    end
    if start_i != nil then
      # Find the latest component c such that c.datetime <= 'end_time':
      end_i = ix_range.bsearch do |i|
        self[i].datetime >= end_time
      end
      if end_i.nil? then
        end_i = count - 1
      elsif end_time < self[end_i].datetime then
        end_i -= 1
      end
      if start_i <= end_i then
        check(self[start_i].datetime >= start_time &&
              self[end_i].datetime <= end_time, "valid start/end range")
        (start_i .. end_i).each do |i|
          result << self[i]
        end
      end
    else
      # start_i == nil: implies all of self's date-times are earlier than
      # 'start_time'; thus, no date-times fall within start_time..end_time
    end
    result
  end

  # The "type" of this report, to be seen by the user
  def component_type
    COMPONENT_TYPE
  end

  # Summary of report contents
  # If 'conversion_function' != nil, it will be called to convert the UTC
  # date/times into the desired (e.g., local-time) time zone.
  def summary(conversion_function = nil, indent = 0, number_formatter = nil)
    spaces = " " * indent
    result = "#{spaces}label: #{label}"
    if empty? then
      result += " (Report is empty.)"
    else
      spaces = " " * indent * 2
      fst = self.first; lst = self.last
      first_datetime = (conversion_function.nil?)?
        fst.datetime: conversion_function.call(fst.datetime)
      last_datetime = (conversion_function.nil?)?
        lst.datetime: conversion_function.call(lst.datetime)
      comp_count = (number_formatter.nil?)? self.count:
        number_formatter.call(self.count)
      result += ", number of components: #{comp_count}\n" +
        "#{spaces}date/time of first component: #{first_datetime}\n" +
        "#{spaces}date/time of last component:  #{last_datetime}"
      result += "\n#{spaces}first component: #{fst}\n" +
      "#{spaces}last component:  #{lst}"
    end
    result
  end

  # Unique list (i.e., no duplicates) of all of the labels that occur in
  # all the messages of all components of 'self'
  post :exists do |result| result != nil && result.is_a?(Array) end
  def message_labels
    if @cached_message_labels.nil? then
      build_message_label_caches
    end
    @cached_message_labels
  end

  # The messages, from all contained reports, associated with 'label'
  def messages_for(label)
    if @cached_message_labels.nil? then
      build_message_label_caches
    end
    @messages_for_label[label]
  end

  # Array containing all matching messages from each ReportComponent
  # If 'pattern' is the symbol :all, all messages of all contained
  # ReportComponents are considered a match.
  pre  :regsym do |p| p != nil && (p.is_a?(Regexp) || p.is_a?(Symbol)) end
  post :array do |result| result != nil && result.is_a?(Array) end
  def matches_for(pattern, use_keys: true, use_values: true, negate: false)
    result = []
    self.each do |r|
      o = r.matches_for(pattern, use_keys: use_keys, use_values: use_values,
                       negate: negate)
      if o.count > 0 then
        o.owner = self
        result << o
      end
    end
    result
  end

  #####  Boolean queries

  post :true_iff_0_count do |result| result == (count == 0) end
  def empty?
    count == 0
  end

  def ===(other)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Measurement

  # Number of contained "ReportComponent"s
  post :natural do |result| result != nil && result >= 0 end
  def count
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Total number of messages in all contained "ReportComponent"s
  post :natural do |result| result != nil && result >= 0 end
  def total_message_count
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Iteration

  def each(&block)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  protected

  COMPONENT_TYPE = "topic"

  def build_message_label_caches
    @messages_for_label = {}
    self.each do |component|
      component.labels.each do |l|
        if ! @messages_for_label.has_key?(l) then
          @messages_for_label[l] = []
        end
        @messages_for_label[l] << component.message_for(l)
      end
    end
    @cached_message_labels = @messages_for_label.keys.sort
  end

end
