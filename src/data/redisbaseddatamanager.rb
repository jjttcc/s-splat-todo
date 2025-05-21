require 'ruby_contracts'
require 'errortools'

# Data manager that uses Redis for its implementation
#!!!!Note: may need to use redis transactions:
#  https://redis.io/docs/latest/develop/interact/transactions/
#  https://redis.io/ebook/part-2-core-concepts/chapter-4-keeping-data-safe-and-ensuring-performance/4-4-redis-transactions/
#  https://medium.com/redis-with-raphael-de-lio/understanding-transactions-in-redis-how-to-3220e83f215c
class RedisBasedDataManager
  include Contracts::DSL, ErrorTools

  public  ###  Access

  attr_reader  :app_name

  attr_reader  :user

  public  ###  Basic operations - Query

  # A hash table of all the keys in the database (for this user/app)
  # for fast searching, with all value components set to true
  def key_table
    result = database.set_members(db_key).map do |k|
      unornamented(k)
    end.to_h { |k| [k, true] }
    result
  end

  # All keys in the database (for this user/app)
  def keys
    result = database.set_members(db_key).map do |k|
      unornamented(k)
    end
    result
  end

  alias_method :handles, :keys

  # Is the key 'handle' in the database?
  def has_key?(handle)
    result = key_table[handle]
  end

  # All "STodoTarget"s, with handle as key, restored from persistent store.
  # A hash table - key is the associated handle.
  # Hash<String, STodoTarget>
  def restored_targets
    result = {}
    keys = database.set_members(db_key)
    keys.each do |k|
      begin
        t = database.object(k)
        if ! t.nil? then
          result[unornamented(k)] = t
          set_db(t)
        end
      rescue Exception => e
        $log.warn(e)
      end
    end
    result
  end

  # All "STodoTarget"s, restored from persistent store.
  # Array<STodoTarget>
  def values
    result = restored_targets.values
    result
  end

  # "STodoTarget" whose handle is 'handle'
  def target_for(handle)
    result = database.object(key_for(handle))
    if ! result.nil? then
      set_db(result)
    end
    result
  end

  alias_method :[], :target_for

  def []=(new_handle, target)
    if target.handle != new_handle then
      target.handle = new_handle
    end
    store_target(target)
  end

  public  ###  Removal

  # Delete the object whose key is based on 'handle' from the database.
  def delete(handle)
    key = key_for(handle)
    database.delete_object(key)
    database.remove_from_set(db_key, key)
  end

  public  ###  Basic operations - Conversion

  # "Legacy" targets (STodoTargets) converted into the new, flat (i.e.,
  # 'children' consist of simply a list of the child handles) format
  def converted_from_legacy(targets)
    puts targets.count
    result = {}
    targets.values.each do |t|
      result[t.handle] = converted(t)
    end
  end

  public  ###  Basic operations - Write

  # Write `targets' out to persistent store.
  def store_targets(targets, replace = false)
# (start-transaction)
    if targets.is_a?(Hash) then
      targets.each do |handle, object|
        check("handles correspond") { object.handle == handle }
        store_target(object, replace)
      end
    else
      check('"targets" is an array') { targets.is_a?(Array) }
      targets.each do |object|
        store_target(object, replace)
      end
    end
# (end-transaction)
  end

  # Store STodoTarget 't' in the databae. Iff 'replace', then replace the
  # old object (with the key formed from t.handle) if it is already in the
  # database.
  def store_target(t, replace = true)
    key = key_for(t.handle)
    if database.exists(key) and ! replace then
      $log.debug "object with handle #{t.handle} is already stored."
    else
      begin
        database.set_object(key, t)
      rescue Exception => e
        $log.warn("database.set_object failed: #{e}")
      end
    end
    database.add_to_set(db_key, key)
  end

  alias_method :update_target, :store_target

  private   ###  Implementation

  # Set "target"'s db attribute to 'self'.
  pre :tgt_not_nil do |tgt| ! tgt.nil? end
  def set_db(target)
    if defined? (target.db=()) then
      target.db = self
    end
  end

  # The string 's' with "#{self.user}." prepended to it and, if app_name is
  # not nil, "#{self.app_name}." is prepended to the above
  def key_for(s)
    result = "#{user}.#{s}"
    if ! app_name.nil? && ! app_name.empty? then
      result = "#{self.app_name}.#{result}"
    end
    result
  end

  # The value of 'key' after stripping the prepended strings (app_name,
  # user)
  def unornamented(key)
    striplength = user.length + 1   # + 1 for '.'
    if ! app_name.nil? && ! app_name.empty? then
      striplength = striplength + app_name.length + 1
    end
    if key.length > striplength then
      result = key[striplength .. -1]
    else
      result = key
    end
    result
  end

  # The specified 'target' (STodoTarget), converted from legacy format to
  # the new "flat" format used in redis.
  def converted(target)
    puts target
    child_list = target.children
    target.children = RedisBasedSet.new(self)
    child_list.each do |c|
      target.children << c
    end
    target
  end

  private   ###  Initialization

  attr_writer    :user, :app_name
  attr_accessor :database, :db_key

  DB_KEY_BASE = 'stodo-database'

  pre  :db_exists do |db| ! db.nil? end
  pre  :user_exists do |user| ! user.nil? end
  post :db_set do |res, db| self.database == db end
  post :user_set do |res, user| self.database == user end
  def initialize(db, user, appname = '')
    self.database = db
    self.user = user
    self.app_name = appname
    self.db_key = key_for(DB_KEY_BASE)
  end

end
