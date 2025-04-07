# !!!!!TO-DO: Move this class to its own file!!!!:
# Matching results from a search of ReportComponent objects
# 'matches':    Hash table containing the matching messages for which, for each
#               element, the key is the message label and the value is the
#               message body
# 'component':  The ReportComponent that owns the matches
# 'owner':      The TopicReport that owns 'component', if available
# 'datetime':   component.datetime
# 'id':         component.id
# 'count':      matches.count
ReportMatchResult = Struct.new(:matches, :component, :owner) do
  public

  def datetime
    component.datetime
  end
  def id
    component.id
  end
  def count
    matches.count
  end
  def matches_for(pattern, use_keys: true, use_values: true, negate: false)
    target = component.new_component(matches)
    result = target.matches_for(pattern, use_keys: use_keys,
                                use_values: use_values, negate: negate)
    result.owner = owner
    result
  end
end

# Components, or elements, of a report, consiting of a timestamp and 0 or
# more labeled messages.
class ReportComponent
  include Contracts::DSL

  public

  #####  Access

  def id
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  alias_method :handle, :id

  # Unix timestamp associated with the component (milliseconds since the epoch)
  post :natural do |result| result != nil && result >= 0 end
  def timestamp
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Date & time associated with 'timestamp'
  post :exists do |result| result != nil end
  def datetime
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Message labels, one per message (i.e., in the same order as 'messages')
  post :enumerable do |result| result != nil && result.is_a?(Enumerable) end
  def labels
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The contents of the report - i.e., one message per label
  post :enumerable do |result| result != nil && result.is_a?(Enumerable) end
  def messages
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # 'matches':  Hash table containing the matching messages for which, for each
  #             element, the key is the message label and the value is the
  #             message body
  def matches
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The message for the specified 'label' (nil if 'label' is not present)
  def message_for(label)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # ReportMatchResult object containing all matching messages
  # If 'pattern' is the symbol :all, all messages of all contained
  # ReportComponents are considered a match.
  # If 'negate' is true, include only messages that don't match pattern.
  pre  :regsym do |p| p != nil && (p.is_a?(Regexp) || p.is_a?(Symbol)) end
  post :result_exists do |result| result != nil end
  post :result_format do |result| result.respond_to?(:id) &&
    result.respond_to?(:datetime) && result.respond_to?(:matches) &&
    result.respond_to?(:count) end
  def matches_for(pattern, use_keys: true, use_values: true, negate: false)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The "type" of this report component, to be seen by the user
  def component_type
    COMPONENT_TYPE
  end

  def to_s
    "handle: #{handle}, #{messages.count} messages"
  end

  #####  Boolean queries

  def ===(other)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Measurement

  # Count of 'messages'
  post :msgs_count do |result| result == self.messages.count end
  def message_count
    messages.count
  end

  alias_method :count, :message_count

  #####  Duplication

  # A new ReportComponent (with the same run-time type as 'self') with
  # contents taken from, if it is not nil, 'label_message_hash' (a hash
  # table whose keys are the labels and associated values the associated
  # messages).  If 'label_message_hash' is nil, the contents are take from
  # those of 'self' (i.e., its 'labels' and 'messages')
  pre  :arg_is_hash do |arg| arg.nil? || arg.is_a?(Hash) end
  post :result do |result| result != nil && result.is_a?(self.class) end
  def new_component(label_message_hash = nil)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  protected

  COMPONENT_TYPE = "topic report component"

end
