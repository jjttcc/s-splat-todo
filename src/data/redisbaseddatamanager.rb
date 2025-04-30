require 'ruby_contracts'

# Data manager that uses Redis for its implementation
#!!!!Note: may need to use redis transactions:
#  https://redis.io/docs/latest/develop/interact/transactions/
#  https://redis.io/ebook/part-2-core-concepts/chapter-4-keeping-data-safe-and-ensuring-performance/4-4-redis-transactions/
#  https://medium.com/redis-with-raphael-de-lio/understanding-transactions-in-redis-how-to-3220e83f215c
class RedisBasedDataManager
  include Contracts::DSL

  public  ###  Access

  attr_reader  :app_name

  attr_reader  :user

  public  ###  Basic operations

  # Write `targets' out to persistent store.
  def store_targets(targets)
    keys = []
# (start-transaction)
    targets.each do |t|
      object = t[1]   # (t[0] is the object's "handle".)
      puts "object: #{object.handle}"
      if database.exists(object.handle) then
        $log.warn "object with handle #{object.handle} is already stored."
      else
        $log.warn "object with handle #{object.handle} is NOT stored."
        key = key_for(object.handle)
        keys << key
        database.set_object(key, object)
      end
    end
binding.irb
    database.replace_set(db_key, keys)
# (end-transaction)
  end

  # "STodoTarget"s restored from persistent store.
  def restored_targets
#!!!binding.irb
    result = {}
    keys = database.set_members(db_key)
    keys.each do |k|
      result[k] = database.object(k)
    end
    result
  end

  private   ###  Implementation

  # The string 's' with "#{self.user}." prepended to it and, if app_name is
  # not nil, "#{self.app_name}." is prepended to the above
  def key_for(s)
    result = "#{user}.#{s}"
    if ! app_name.nil? then
      result = "#{self.app_name}.#{result}"
    end
    result
  end

  private   ###  Initialization

  attr_writer    :user, :app_name
  attr_accessor :database, :db_key

  DB_KEY_BASE = 'stodo-database'

  pre  :db_exists do |db| ! db.nil? end
  pre  :user_exists do |user| ! user.nil? end
  post :db_set do |res, db| self.database == db end
  post :user_set do |res, user| self.database == user end
  def initialize(db, user, appname = nil)
#!!!binding.irb
    self.database = db
    self.user = user
    self.app_name = appname
    self.db_key = key_for(DB_KEY_BASE)
  end

end
