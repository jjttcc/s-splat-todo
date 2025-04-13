require 'report_component'

# Redis-stream-based implementation of ReportComponent
class RedisReportComponent < ReportComponent
  include Contracts::DSL

  public

  #####  Access

  attr_reader :id

  alias_method :handle, :id

  def timestamp
    id[0..id.index("-")-1].to_i
  end

  def datetime
    if @datetime.nil? then
      @datetime = DateTime.strptime(id[0..9], "%s")
    end
    @datetime
  end

  def labels
    contents.keys
  end

  def messages
    contents.values
  end

  def matches
    contents
  end

  def message_for(label)
    contents[label]
  end

  def matches_for(pattern, use_keys: true, use_values: true, negate: false)
    matches = {}
    if pattern == :all then
      matches = contents.clone
    elsif negate then
      contents.each do |key, value|
        if
          (! use_keys || key !~ pattern) && (! use_values || value !~ pattern)
        then
          matches[key] = value
        end
      end
    else
      contents.each do |key, value|
        if
          (use_keys && key =~ pattern) || (use_values && value =~ pattern)
        then
          matches[key] = value
        end
      end
    end
    ReportMatchResult.new(matches, self)
  end

  #####  Boolean queries

  def ===(other)
    other != nil && contents == other.contents &&
      timestamp == other.timestamp
  end

  #####  Duplication

  def new_component(label_message_hash = nil)
    guts = label_message_hash
    if guts.nil? then
      guts = self.contents
    end
    self.class.new(id: self.id, guts: guts)
  end

  private

  attr_reader :contents

  pre  :id do |hash| hash[:id] != nil end
  pre  :guts do |hash| hash[:guts] != nil && hash[:guts].is_a?(Hash) end
  post :id do |res, hash| self.id != nil && self.id == hash[:id] end
  post :timestamp do timestamp != nil end
  post :contents do contents != nil && contents.is_a?(Hash) end
  def initialize(id:, guts:)
    @id = id
    @contents = guts
  end

end
