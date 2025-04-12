require 'topic_report'
require 'report_tools'
require 'local_time'

# Reports on the status of the system, services, etc. - consisting of
# "TopicReport"s
class StatusReport
  include Contracts::DSL, Enumerable, ReportTools, LocalTime

  public

  #####  Access

  # The date & time, in seconds, the report was created (Unix timestamp - i.e.,
  # seconds since the "epoch")
  post :natural do |result| result != nil && result >= 0 end
  def timestamp
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The date & time the report was created as a DateTime (based on 'timestamp')
  post :natural do |result| result != nil && result >= 0 end
  def date_time
    DateTime.strptime(timestamp.to_s, "%s")
  end

  # Enumerable contents - i.e., 0 or more of TopicReport
  post :enumerable do |result| result != nil && result.is_a?(Enumerable) end
  post :counts_match do |result| result.count == self.count end
  def topic_reports
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The label for each element (TopicReport) of 'topic_reports'
  post :enumerable do |result| result != nil && result.is_a?(Enumerable) end
  def labels
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The topic report for 'label'
  pre  :label do |label| label != nil end
  post :topic do |result| implies(result != nil, result.is_a?(TopicReport)) end
  def [](label)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The topic report for 'label'
  pre  :label do |label| label != nil end
  post :topic do |result| implies(result != nil, result.is_a?(TopicReport)) end
  def report_for(label)
    self[label]
  end

  # Array containing all matching components from each TopicReport
  # If 'pattern' is the symbol :all, all messages of all contained
  # ReportComponents are considered a match.
  pre  :regsym do |p| p != nil && (p.is_a?(Regexp) || p.is_a?(Symbol)) end
  post :array do |result| result != nil && result.is_a?(Array) end
  def matches_for(pattern, use_keys: true, use_values: true, negate: false)
    result = []
    self.each do |r|
      result.concat(r.matches_for(pattern, use_keys: use_keys,
                                 use_values: use_values, negate: negate))
    end
    result
  end

  # The "type" of this report, to be seen by the user
  def component_type
    COMPONENT_TYPE
  end

  # Summary of report contents
  def summary
    result = "Number of sub-reports: #{count}, date/time: " +
      "#{local_time(date_time)}\n" +
      wrap("Labels: #{labels.join(", ")}", 79, '  ') + "\n"
    subcount = sub_counts.inject(0){|sum,x| sum + x }
    result += "Component count: #{number_with_delimiter(subcount)}\n"
    result
  end

  #####  Boolean queries

  def ===(other)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Measurement

  # Array: count of each of 'topic_reports'
  post :enumerable do |result| result != nil && result.is_a?(Enumerable) end
  def sub_counts
    topic_reports.each.map { |r| r.count }
  end

  #####  Iteration

  def each(&block)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  protected

  COMPONENT_TYPE = "status"

end
