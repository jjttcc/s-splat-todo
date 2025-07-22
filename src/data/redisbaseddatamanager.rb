require 'ruby_contracts'
require 'errortools'
require 'stodo_global_constants'

# Data manager that uses Redis for its implementation
#!!!!Note: may need to use redis transactions:
#  https://redis.io/docs/latest/develop/interact/transactions/
#  https://redis.io/ebook/part-2-core-concepts/chapter-4-keeping-data-safe-and-ensuring-performance/4-4-redis-transactions/
#  https://medium.com/redis-with-raphael-de-lio/understanding-transactions-in-redis-how-to-3220e83f215c
class RedisBasedDataManager
  include Contracts::DSL, ErrorTools, STodoGlobalConstants

  public  ###  app_name and user access/setting

  # The application name associated with a particular user-client-session
  attr_reader  :app_name

  # The user name associated with a particular user-client-session
  attr_reader  :user

  # Boolean: Skip adding user/appname to ALL_USER_APP_COMBINATIONS_KEY set?
  attr_accessor :skip_global_set_add

  # Set 'app_name' and 'user'.
  pre :args_exist do |aname, u|
    ! (aname.nil? || u.nil?) && ! (aname.empty? || u.empty?)
  end
  def set_appname_and_user(aname, u)
    @app_name = aname
    @user = u
    self.db_key = key_for(DB_KEY_BASE)
    if ! skip_global_set_add then
      # Add the user:app combination to the global set
binding.irb
      database.add_to_set(
        STodoGlobalConstants::ALL_USER_APP_COMBINATIONS_KEY,
        "#{user}:#{app_name}")
    end
  end

  public  ###  Basic operations - Query

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
    result = database.set_has(db_key, key_for(handle))
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
  # Raises an exception if the write fails.
  def store_target(t, replace = true)
    key = key_for(t.handle)
    if database.exists(key) and ! replace then
      $log.warn "object with handle #{t.handle} is already stored."
    else
      begin
        database.set_object(key, t)
        database.add_to_set(db_key, key)
      rescue Exception => e
        msg = "database.set_object failed: #{e}\n" +
                  "#{e.backtrace.join("\n")}"
        $log.warn(msg)
        raise msg
      end
    end
  end

  private   ###  Implementation

  # A hash table of all the keys in the database (for this user/app)
  # for fast searching, with all value components set to true
  # Warning: This method call is expensive.
  def key_table
    result = database.set_members(db_key).map do |k|
      unornamented(k)
    end.to_h { |k| [k, true] }
    result
  end

  # Set "target"'s db attribute to 'self'.
  pre :tgt_not_nil do |tgt| ! tgt.nil? end
  def set_db(target)
    if defined? (target.db=()) then
      target.db = self
    end
  end

  # The string 's' with "#{self.user}." and #{self.app_name}." prepended
  # to it
  pre :args_exist do
    ! (user.nil? || app_name.nil?) && ! (user.empty? || app_name.empty?)
  end
  def key_for(s)
    result = "#{user}.#{app_name}.#{s}"
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

  attr_accessor :database, :db_key

  DB_KEY_BASE = 'stodo-database'

  pre :db_exists do |db| ! db.nil? end
#!!!remove these pre/post?:
#  pre :usr_appname_exist do |db, u, aname|
#    ! (aname.nil? || u.nil?) && ! (aname.empty? || u.empty?)
#  end
#  post :user_set do |res, user| self.database == user end
  post :db_set do |res, db| self.database == db end
  def initialize(db, user, appname, skip_global_set_add: false)
    self.skip_global_set_add = skip_global_set_add
    self.database = db
    if ! user.nil? && ! appname.nil? then
      set_appname_and_user(appname, user)
#    else
#[obsolete - remove this else block]
#      raise "RedisBasedDataManager.initialize: user and appname must not" +
#        "be nil"
    end
  end

end
