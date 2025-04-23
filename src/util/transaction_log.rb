require 'ruby_contracts'

# Operations and tools related to transactions and transaction-related
# logging
class TransactionLog
  include Contracts::DSL

  public  ### Attributes

  attr_reader :user

  # The device used for logging transactions
  attr_reader :transaction_logging_device

  public  ###  Access

  # List of all transaction ids
  def transaction_ids
    transaction_logging_device.queue_contents(transaction_id_queue_key)
  end

  # The keys of the log entries for 'transaction_id' - If 'transaction_id'
  # is nil, the log keys for the last logged transaction.
  def log_keys(transaction_id = nil)
    result = []
    trid = transaction_id
    if trid.nil? then
      trid = transaction_logging_device.queue_tail(transaction_id_queue_key)
    end
    if ! trid.nil? then
      result = transaction_logging_device.queue_contents(trid)
    end
  end

  # All logged messages associated with 'transaction_id'
#!!!to-do: Document the structure of 'result'.
  def log_messages(transaction_id = nil)
    result = []
    lkeys = log_keys(transaction_id)
    lkeys.each do |key|
      result << message_logging_device.contents(key)
    end
    result
  end

  public  ###  Status report

  # The id of the current transaction for 'user' - nil if no transactions
  # are open
  def current_transaction
    transaction_logging_device.retrieved_message(current_transaction_key)
  end

  # Has a transaction been started?
  def in_transaction
    ! current_transaction.nil?
  end

  public  ###  Basic operations

  # Begin the transaction.
  def start_transaction
    transaction_id = "trx:" + TimeUtil.current_nano_date_time
    transaction_logging_device.add_msgs_to_queue(transaction_id_queue_key,
                                                 transaction_id)
    transaction_logging_device.set_message(current_transaction_key,
                                           transaction_id)
  end

  # End the transaction.
  def end_transaction
    transaction_logging_device.delete_object(current_transaction_key)
  end

  # Add the specified logging 'key' to the queue identified by
  # self.current_transaction. Do nothing if the queue already contains the
  # key.
  pre :in_transaction do self.in_transaction end
  def add_log_key(key)
    if
      ! transaction_logging_device.queue_contains(current_transaction, key)
    then
      transaction_logging_device.add_msgs_to_queue(current_transaction, key)
    end
  end

=begin
  def write(message)
# example 'message':
#W, [2025-04-09T17:03:56.421626 #3333547]  WARN -- : a logger device
    message =~ /([a-zA-Z], *[^:]*:..:[^:]*): (.*)/
    header = $1
    msg = $2
    # save 'msg' to the redis log.
    redis_log.send_message(log_key: stream_key, tag: header, msg: msg)
  end
=end

  protected

  attr_writer   :user, :transaction_logging_device

  # The device used for accessing log entries
  attr_accessor :message_logging_device

  pre  :transaction_logging_device do |trlogdev| ! trlogdev.nil?  end
  pre  :message_logging_device do |td, msglogdev| ! msglogdev.nil?  end
  pre  :user do |td, md, user| ! user.nil?  end
  post :transaction_logging_device_set do |result, logdev|
    self.transaction_logging_device == logdev
  end
  post :user_set do |result, logdev, msglogdev, user|
    self.user == user
  end
  def initialize(trx_logging_device, msg_logging_device, user)
    self.transaction_logging_device = trx_logging_device
    self.message_logging_device = msg_logging_device
    self.user = user
  end

  private

  pre :good_user do ! self.user.nil? && ! self.user.empty? end
  def transaction_id_queue_key
    "#{user}.transaction-id-queue"
  end

  def current_transaction_key
    "#{user}-current-transaction"
  end

end
