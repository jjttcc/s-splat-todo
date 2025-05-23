require 'ruby_contracts'
require 'errortools'

class RedisBasedSet
  include Enumerable, ErrorTools
  include Contracts::DSL

  public  ###  Status report

  def empty?
    handles.empty?
  end

  public  ###  Iteration

  def each(&block)
    check(:stodo_targets_set) { ! stodo_targets.nil? }
    if stodo_targets.empty? then
      load_targets
    end
    stodo_targets.each do |key, value|
      block.call(value)
    end
  end

  public  ###  Element change

  def <<(t)
    handles << t.handle
  end

  # Merge (append) an array or enumerable of STodoTarget.
  def merge(enumerable)
    if ! defined? handles || handles.nil? then
      init_handles
      init_stodo_targets
    end
    handles.merge(enumerable.map { |e| e.handle })
  end

  # To be called when this object is loaded from the database.
  def set_db(db)
    if ! defined?(@@database) || @@database.nil? then
      @@database = db
    end
    if ! defined? handles || handles.nil? then
      init_handles
      init_stodo_targets
    end
  end

  public  ###  Removal

  def delete(target)
    h = target.handle
    old_count = handles.count
    handles.delete(h)
    if old_count > handles.count then
      stodo_targets.delete(h)
    end
  end

  def delete_if(&block)
    if stodo_targets.nil? then
      init_handles
      init_stodo_targets
    end
    if stodo_targets.empty? then
      load_targets
    end
    stodo_targets.each do |key, value|
      if block.call(value) then
        delete(value)
      end
    end
  end

  def clear
    init_handles
    init_stodo_targets
  end

  public  ###  Database-related methods

  def prepare_for_db_write
    init_stodo_targets
  end

  private

  attr_accessor :handles, :stodo_targets

  pre :db_not_nil do |db| ! db.nil? end
  def initialize(db)
    if ! defined?(@@database) || @@database.nil? then
      @@database = db
    end
    init_handles
    init_stodo_targets
  end

  private ### Utilities

  def init_handles
    self.handles = Set.new
  end

  def init_stodo_targets
    self.stodo_targets = {}
  end

  private ### Database

  # Load the STodoTargets from the database, identified by 'handles'.
  pre :db_exists do defined?(@@database) && ! @@database.nil? end
  pre :targets_exist do ! stodo_targets.nil? end
  def load_targets
    db = @@database
    handles.each do |h|
      t = db[h]
      if ! t.nil? then
        stodo_targets[h] = t
      else
        # There is no STodoTarget with handle 'h' in the database.
      end
    end
  end

end
