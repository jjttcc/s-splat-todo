require 'ruby_contracts'
require 'yaml/store'
require 'securerandom'
require 'errortools'

# Data manager that uses YAML::Store for its implementation
class YamlStoreBasedDataManager
  include ErrorTools
  include Contracts::DSL

  public

  LAST_UPDATE_TAG = :last_update
  # Name of the database file:
  STORED_OBJECTS_FILENAME = 'stodo_data.store'
  # Path of last performed temporary backup:
  attr_reader :last_temp_backup_path

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
  pre 'backup_paths != nil' do |backup_paths| ! backup_paths.nil? end
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

  # Export the items with the specified 'handles' to the file-path
  # indicated by 'path'. If 'recursive', include all descendants of the
  # specified items.
  pre 'handles' do |handles| ! handles.nil? end
  pre 'path valid' do |h, p| ! p.nil? && ! p.empty? end
  def export(handles, path, recursive = false)
    all_targets = restored_targets
    items = {}
    handles.each do |h|
      i = all_targets[h]
      if i then
        items[h] = i
        if recursive then
          i.descendants.each do |d|
            items[d.handle] = d
          end
        end
      else
        $log.warn "#{h}: invalid handle"
      end
    end
    perform_backup([path], nil, items)
  end

  # Perform a temporary backup of the database, with an ad hoc, unique file
  # name. If the backup succeeds, make the path of the file used for the
  # backup available as:
  #   self.last_temp_backup_path
  post 'last_temp_backup_path != nil' do ! self.last_temp_backup_path.nil? end
  def perform_temporary_backup
    self.last_temp_backup_path =
      "#{@stored_fpath}.#{SecureRandom.alphanumeric}"
    tmp_path = self.last_temp_backup_path
    begin
      $log.warn "backing up to #{tmp_path}"
      if ! File.exist?(tmp_path) then
        # 'perform_backup' expects the file to already exist:
        File.new(tmp_path, "w+").close
      end
      pathlist = [tmp_path]
      @store.transaction(true) do
        perform_backup(pathlist, nil, @store[@user], false)
      end
    rescue Exception => e
      self.last_temp_backup_path = ""
      $log.warn "#{e} (stack trace:\n"+e.backtrace.join("\n")+')'
    end
  end

  private

  attr_writer :last_temp_backup_path

  # If 'data_path' is a file, assume it's the database file; otherwise
  # (it's a directory), use it to determine the database file's path,
  # with STORED_OBJECTS_FILENAME as the file name.
  def initialize(data_path, user)
    @user = user
    if File.file?(data_path) then
      @stored_fpath = data_path
    else
      @stored_fpath = data_path + File::SEPARATOR + STORED_OBJECTS_FILENAME
    end
    @store = YAML::Store.new(@stored_fpath)
    @store.ultra_safe = true
  end

  # Perform a backup of 'source_targets' to each file in 'destinations' if
  # they are out of date with respect to last_source_update. If
  # last_source_update is nil, do the backup unconditionally.
  # 'source_targets' is a hash table of items whose keys are the respective
  # item handles.
  # If 'dests_are_directories', then assume each path in
  # 'destinations' is a directory and append
  # 'STORED_OBJECTS_FILENAME' to produce the database filename;
  # otherwise, assume each path is the path of the database file.
  # Note: It is assumed that a transaction is active for the @store
  # database.
  def perform_backup(destinations, last_source_update, source_targets,
                    dests_are_directories = true)
    if source_targets == nil then
      $log.warn "No data found in source database."
    else
      destinations.each do |path|
        if dests_are_directories then
          backup_file_path = path + File::SEPARATOR +
            STORED_OBJECTS_FILENAME
        else
          backup_file_path = path
        end
        $log.debug "backup_file_path: #{backup_file_path}"
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
      # Override 'private' status of t.prepare_for_db_write.
      t.send(:prepare_for_db_write)
    end
    dbstore[@user] = tgts
    dbstore[LAST_UPDATE_TAG] = Time.now
  end

end
