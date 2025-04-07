# Abstract interface for log access functionality
module LogReader
  include Contracts::DSL

  public

  #####  Access

  # The entire log contents for 'key' - if 'count' != nil, it will be used
  # as a limit for the number of entries returned; otherwise, there is no
  # size limit for the result.
  pre  :args_hash  do |hash| hash.respond_to?(:to_hash) end
  pre  :key_exists do |hash| hash.has_key?(:key) && hash[:key] != nil end
  post :result do |res| res != nil && res.is_a?(Array) end
  def contents(key:, count: nil)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The log contents for the specified keys in args_hash[:key_list]
  # If args_hash[:key_list] includes the string "*" (i.e., one-character
  # string that is an asterisk), all available keys will be queried.
  # Other specifications or options may be present in 'args_hash' depending
  # on the run-time type of the LogReader object (i.e., the class that
  # includes LogReader that is used to instantiate this object)
  pre  :args_hash do |hash| hash != nil && hash.respond_to?(:to_hash) end
  pre  :has_keylist do |hash| hash.has_key?(:key_list) end
  post :hash_result do |r| r != nil && r.is_a?(Hash) end
  def contents_for(args_hash)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Measurement

#{:count=>23755, "length"=>23755, "radix-tree-keys"=>259, "radix-tree-nodes"=>541, "groups"=>0, "last-generated-id"=>"1574128627983-0", "first-entry"=>["1573787219125-0", ["eod_data_retrieval_status", "running@2019-11-15 03:06:59 UTC"]], "last-entry"=>["1574128627983-0", ["eod_data_retrieval_status", "running@2019-11-19 01:57:07 UTC"]]},

  # Information for each key specified via args_hash[:key_list] - parallels
  # 'contents_for', with the difference that instead of returning the contents
  # for each specified key, the result is simply a set of associated "info"
  # (such as the count of entries).
  # 'result' is a hash-table of hash-tables such that:
  # For each key, k, in args_hash[:key_list], result[:k] will hold the
  # following key/value pairs:
  #   :count        -> The number of elements associated with :k
  #   :first_entry  -> The first log entry for key :k
  #   :last_entry   -> The last  log entry for key :k
  # In addition, for debugging (or further analysis, etc.), all information
  # returned by the implementation being used will, if practical (e.g., it
  # is not extremely large), be included as further key/value pairs.  (Any
  # other keys/options in 'args_hash' other than :key_list will be ignored.)
  pre  :args_hash do |hash| hash != nil && hash.respond_to?(:to_hash) end
  pre  :has_keylist do |hash| hash.has_key?(:key_list) end
  post :hash_result do |r| r != nil && r.is_a?(Hash) end
  def info_for(args_hash)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Removal

  # Delete all contents associated with the specified key list.
  pre :key_list do |hash| hash != nil && hash[:key_list] != nil end
  pre :valid_keys do |hash| hash[:key_list].is_a?(Enumerable) ||
    hash[:key_list].respond_to?(:to_sym) end
  def delete_contents(key_list:)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Trim contents associated with the specified keys (args_hash[:key_list]),
  # according to the other options/arguments contained in 'args_hash' and
  # the semantics implemented via the run-time type of 'self'.
  pre :args_hash do |args| args != nil && args.respond_to?(:to_hash) end
  pre :has_keylist do |args| args.has_key?(:key_list) end
  pre :valid_keys do |args| args[:key_list].is_a?(Enumerable) ||
    args[:key_list].respond_to?(:to_sym) end
  def trim_contents(args_hash)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

end
