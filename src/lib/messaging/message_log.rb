# Message-logging interface
module MessageLog
  include Contracts::DSL

  public

  #####  Access

  # The "key" used to access (when reading) or mark (when writing) the
  # desired log contents
  post :exists do |result| result != nil end
  post :size   do |result| result.respond_to?(:size) && result.size > 0 end
  def key
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The entire log contents (associated with 'key') - if 'count' != nil, it
  # will be used as a limit for the number of entries returned; otherwise,
  # there is no size limit for the result.
  post :result do |result| result != nil && result.is_a?(Array) end
  def contents(count: nil)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Basic operations

  # Send the specified tag: msg pair to the log (with key 'log_key', if
  # specified - otherwise with self.key).
  # pre :good_args do |hash| ! (hash[:tag].nil? || hash[:msg].nil?) end
  def send_message(log_key: key, tag:, msg:)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Send the specified hash-table of messages (:messages_hash) to the log
  # (with key 'log_key', if specified - otherwise with self.key).
  # pre :mhash do |hash|
  #   hash[:messages_hash] != nil && hash[:messages_hash].is_a?(Hash) end
  def send_messages(log_key: key, messages_hash:)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  State-changing operations

  # Change the logging 'key' to 'new_key'.
  pre  :good_key do |new_key| new_key != nil && new_key.size > 0 end
  post :key_set  do |new_key| key == new_key end
  def change_key(new_key)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

end
