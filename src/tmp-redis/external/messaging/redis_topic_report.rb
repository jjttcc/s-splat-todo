require "set"
require 'redis_report_component'
require 'topic_report'

# Redis-stream-based implementation of TopicReport
class RedisTopicReport < TopicReport
  include Contracts::DSL, Util

  public

  #####  Access

  # topic label (or "handle")
  attr_reader :label

  alias_method :handle, :label

  def [](index)
    result = @components[index]
    if result.nil? && @raw_contents[index] != nil then
      component_parts = @raw_contents[index]
      result = RedisReportComponent.new(id: component_parts.first,
                                   guts: component_parts[1])
      @components[index] = result
    end
    result
  end

  #####  Boolean queries

  def empty?
    components.empty?
  end

  def ===(other)
    other != nil && raw_contents == other.raw_contents &&
      timestamp == other.timestamp
  end

  #####  Measurement

  def count
    @components.count
  end

  # Total number of messages in all contained "ReportComponent"s
  post :natural do |result| result != nil && result >= 0 end
  def total_message_count
    result = 0
    raw_contents.each do |e|
      result += e.count
    end
    result
  end

  #####  Iteration

  def each(&block)
    (0 .. raw_contents.count - 1).each do |i|
      # (Call self[](i) to ensure that a ReportComponent exists at i.)
      block.call(self[i])
    end
  end

  private

  attr_reader :components, :raw_contents

  pre :label do |hash| hash[:label] != nil end
  pre :guts do |hash| hash[:guts] != nil && hash[:guts].is_a?(Array) end
  post :label_set do self.label != nil end
  post :components do components != nil && components.is_a?(Array) end
  post :raw do raw_contents != nil && raw_contents.is_a?(Array) end
  def initialize(label:, guts:)
    @label = label
    # (Use SortedSet to ensure raw_contents is sorted.)
    @raw_contents = SortedSet.new(guts).map {|e| e}
    @components = Array.new(@raw_contents.count)
  end

end
