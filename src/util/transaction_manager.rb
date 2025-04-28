require 'ruby_contracts'

# Operations and tools related to transactions and transaction-related
# logging
class TransactionManager
  include Contracts::DSL, SpecTools

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
      trid = previous_queued_transaction
    end
    if ! trid.nil? then
      result = transaction_logging_device.queue_contents(trid)
    end
  end

  # All logged messages associated with 'transaction_id'
  # If 'transaction_id' is nil, the logged messages for the last logged
  # transaction.
  # structure of 'result': Array<Array<String, Hash>>
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
  pre  :not_in_transaction do ! in_transaction end
  post :in_transaction do in_transaction end
  def start_transaction
    transaction_id = "trx:" + TimeUtil.current_nano_date_time
    transaction_logging_device.add_msgs_to_queue(transaction_id_queue_key,
                                                 transaction_id)
    transaction_logging_device.set_message(current_transaction_key,
                                           transaction_id)
  end

  # End the transaction.
  post :not_in_transaction do ! in_transaction end
  def end_transaction
    if in_transaction then
      transaction_logging_device.delete_object(current_transaction_key)
    end
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
  post :message_logging_device_set do |result, ld, mlogdev|
    self.message_logging_device == mlogdev
  end
  post :user_set do |result, logdev, msglogdev, user|
    self.user == user
  end
  post :in_transaction_unless_suppressed do
    implies(ENV[SUPPRESS_TRANSACTION].nil?, in_transaction)
  end
  def initialize(trx_logging_device, msg_logging_device, user)
    self.transaction_logging_device = trx_logging_device
    self.message_logging_device = msg_logging_device
    self.user = user
    if ENV[SUPPRESS_TRANSACTION].nil? then
      wrap_transaction
    end
  end

  private

  # If we're not in a transaction, start one (start_transaction), and
  # then ensure that the transaction is closed (end_transaction) when the
  # process exits.
  post :in_transaction do in_transaction end
  def wrap_transaction
    if ! in_transaction then
      if @cached_previous_queued_transaction.nil? then
        # Ensure that this transaction that we are starting below is
        # not reported as the 'previous_queued_transaction':
        @cached_previous_queued_transaction = previous_queued_transaction
      end
      start_transaction
      at_exit { end_transaction }
    end
  end

  pre :good_user do ! self.user.nil? && ! self.user.empty? end
  def transaction_id_queue_key
    "#{user}.transaction-id-queue"
  end

  def current_transaction_key
    "#{user}-current-transaction"
  end

  # The id of the last transaction logged in the database
  def previous_queued_transaction
    if ! @cached_previous_queued_transaction.nil? then
      @cached_previous_queued_transaction
    else
      transaction_logging_device.queue_tail(transaction_id_queue_key)
    end
  end

end
