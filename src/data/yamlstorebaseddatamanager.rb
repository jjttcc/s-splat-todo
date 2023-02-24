require 'ruby_contracts'
require 'yaml/store'
require 'errortools'

class YamlStoreBasedDataManager
  include ErrorTools
  include Contracts::DSL

  LAST_UPDATE_TAG = :last_update

  public

  # Write `tgts' out to persistent store.
  def store_targets(tgts)
    @store.transaction do
      perform_target_storage(tgts, @store)
    end
  end

  # "STodoTarget"s restored from persistent store.
  def restored_targets
    result = nil
    @store.transaction(true) do
      result = @store[@user]
    end
    if result == nil then result = {} end
    result
  end

  # Back up the database file to the paths in 'backup_paths'.
  # precondition: backup_paths != nil
  pre 'backup_paths != nil' do |backup_paths| backup_paths != nil end
  def backup_database(backup_paths)
    begin
      if backup_paths.empty? then
        $log.warn "No backup paths configured: backup aborted."
      else
        @store.transaction(true) do
          last_source_update = @store[LAST_UPDATE_TAG]
          source_targets = @store[@user]
          perform_backup(backup_paths, last_source_update, source_targets)
        end
      end
    rescue Exception => e
      $log.warn "#{e} (stack trace:\n"+e.backtrace.join("\n")+')'
    end
  end

  private

  STORED_OBJECTS_FILENAME = 'stodo_data.store'

  def initialize(data_path, user)
    @data_path = data_path
    @user = user
    @stored_fpath = @data_path + File::SEPARATOR + STORED_OBJECTS_FILENAME
    @store = YAML::Store.new(@stored_fpath)
    @store.ultra_safe = true
  end

  # Perform a backup of @store to each file in 'destinations' if they are
  # out of date with respect to last_source_update.
  # Note: It is assumed that a transaction is active for the @store
  # database.
  def perform_backup(destinations, last_source_update, source_targets)
    if source_targets == nil then
      $log.warn "No data found in source database."
    else
      destinations.each do |path|
        backup_file_path = path + File::SEPARATOR + STORED_OBJECTS_FILENAME
        backupstore = YAML::Store.new(backup_file_path)
        begin
          backupstore.transaction do
            last_dest_update = backupstore[LAST_UPDATE_TAG]
            $log.debug "lsu, ldu: #{last_source_update}, #{last_dest_update}"
            if
              last_source_update == nil || last_dest_update == nil ||
                last_source_update > last_dest_update
            then
              perform_target_storage(source_targets, backupstore)
            end
          end
        rescue Exception => e
          $log.warn "#{e} (stack trace:\n"+e.backtrace.join("\n")+')'
        end
      end
    end
  end

  def perform_target_storage(tgts, dbstore)
    tgts.values.each do |t|
      t.prepare_for_db_write
    end
    dbstore[@user] = tgts
    dbstore[LAST_UPDATE_TAG] = Time.now
  end

end
