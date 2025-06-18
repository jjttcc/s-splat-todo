require 'ruby_contracts'
require 'stodomanager'

# STodoManager that uses redis.
class RedisSTodoManager < STodoManager
  include ErrorTools, Contracts::DSL

  public

  ###  Queries

  def selected_targets
    handles = @data_manager.keys.select do |h|
      yield h
    end
    result = handles.map { |h| @data_manager.target_for(h) }
  end

  def selected_handles
    handles = @data_manager.keys.select do |h|
      yield h
    end
  end

  ###  Basic operations

  # Ensure that the specified targets are updated in persistent store.
  def update_targets options
    if ! target_builder.targets_prepared? then
      target_builder.prepare_targets
    end
    target_builder.process_targets
    edits = target_builder.edited_targets
    if ! edits.empty? then
      repo = configuration.stodo_git
      repo.update_items_and_commit(edits, options.commit_message, true)
    end
    @data_manager.store_targets(edits, true)
  end

  def editor
    if @editor == nil then
      @editor = STodoTargetEditor.new(@data_manager)
    end
    @editor
  end

  private

  ###    Initialization

  def initialize_existing_targets
    @existing_targets = @data_manager
  end

  ###    Implementation

  pre :tgt_exists do |tgt| ! tgt.nil? end
  def store_target(tgt)
    if ! tgt.connected_to_database then
      tgt.db = @data_manager
    end
    tgt.force_update
  end

  def target_for(handle)
    @data_manager.target_for(handle)
  end

  def save_new_targets
    @new_targets.values.each do |t|
      if ! t.connected_to_database then
        t.db = @data_manager
      end
      t.force_update
    end
  end

  def update_database(targets = nil)
    # null-op
  end

end
