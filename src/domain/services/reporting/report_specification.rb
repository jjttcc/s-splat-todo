require 'json'
require 'ruby_contracts'

# Value (immutable) objects that mimic a read-only Hash to provide the
# specifications for a status report
class ReportSpecification
  include Contracts::DSL

  public

  #####  Constants

  # Values of keys used for reporting
  REPORT_TYPE_KEY, REPORT_KEY_KEY, KEYS_KEY, BLOCK_KEY, NEW_KEY, COUNT_KEY =
    :type, :response_key, :key_list, :block_msecs, :new_only, :count
  START_TIME_KEY, END_TIME_KEY = :start_time, :end_time

  CREATE_TYPE, CLEANUP_TYPE, INFO_TYPE = :create, :cleanup, :info
  REPORT_TYPES = {
    CREATE_TYPE => true, CLEANUP_TYPE => true, INFO_TYPE => true
  }

  BLOCK_MSECS_DEFAULT = 2000

  QUERY_KEYS = [REPORT_TYPE_KEY, REPORT_KEY_KEY, KEYS_KEY, BLOCK_KEY, NEW_KEY,
                COUNT_KEY, START_TIME_KEY, END_TIME_KEY]

  QUERY_KEY_MAP = Hash[QUERY_KEYS.map {|e| [e, true]}]

  #####  Access

  # The type of report-related action being requested
  attr_reader :type

  # The key with which the StatusReporting object is expected to log its
  # response - the report results
  attr_reader :response_key

  # The list of keys for which log entries are to be retrieved
  attr_reader :key_list

  # Count of entries involved in the report/operation, if needed
  attr_reader :count

  # Starting and ending date/time for the report: String: seconds since
  # the "epoch" (UNIX timestamp) - nil means no (start/end) restriction
  attr_reader :start_time, :end_time

  attr_reader :block_msecs, :new_only

  # The hash-table/arguments needed to retrieve the ordered report
  post :is_hash do |result| result != nil && result.is_a?(Hash) end
  def retrieval_args
    self.to_hash
  end

  pre :is_key do |k| k.is_a?(Symbol) || k.is_a?(String) end
  def [](key)
    result = nil
    if QUERY_KEY_MAP[key.to_sym] then
      result = self.send(key)
    end
    result
  end

  def keys
    self.to_hash.keys
  end

  #####  Boolean queries

  pre :is_key do |k| k.is_a?(Symbol) || k.is_a?(String) end
  def has_key?(key)
    QUERY_KEY_MAP[key.to_sym]
  end

  #####  Conversion

  # (To provide arguments to LogReader.contents_for)
  def to_hash
    result = Hash[ QUERY_KEY_MAP.keys.map do |e|
      [e, self[e]]
    end]
    result
  end

  def to_str
    self.to_hash.to_json
  end

  def to_json
    self.to_hash.to_json
  end

  private

  # Valid arguments ('contents' keys/values):
  #   :type          - type of report being requested
  #   :key_list      - list of logging keys to include in report
  #   :count         - limit for # of log entries per key to include
  #   :start_time    - starting date/time for report
  #   :end_time      - ending date/time for report
  #   :response_key  - key for reporting service to use for response
  #   :new_only
  #   :block_msecs
  pre  :contents do |contents| contents != nil end
  pre  :valid_type do |contents| ! contents.is_a?(Hash) ||
    contents[:type] != nil && REPORT_TYPES[contents[:type]] end
  post :new_only_boolean do |result|
    new_only.is_a?(TrueClass) || new_only.is_a?(FalseClass) end
  post :type_valid do self.type != nil && REPORT_TYPES[self.type] end
  def initialize(contents)
    if contents.is_a?(String) then
      contents = JSON.parse(contents.to_str, symbolize_names: true)
    elsif contents.is_a?(ReportSpecification)
      contents = contents.to_hash
    end
    if ! contents.is_a?(Hash) then
      raise "Invalid argument to 'new': #{contents}"
    end
    @type = contents[:type].to_sym
    @response_key = contents[:response_key].to_sym
    if contents[:key_list].is_a?(Enumerable) then
      @key_list = contents[:key_list].map {|e| e.to_sym}
    else
      @key_list = [contents[:key_list]] # I.e., coerce it to an Array.
    end
    @block_msecs = contents[:block_msecs]
    if contents[:new_only].nil? then
      @new_only = false
    else
      @new_only = !! contents[:new_only]
    end
    if contents[:count] != nil then
      @count = contents[:count]
    end
    if contents[:start_time] != nil then
      @start_time = contents[:start_time]
    end
    if contents[:end_time] != nil then
      @end_time = contents[:end_time]
    end
  end

end
