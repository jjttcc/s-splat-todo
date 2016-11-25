require 'yaml/store'

class YamlStoreBasedDataManager

  public

  # Write `tgts' out to persistent store.
  def store_targets(tgts)
    @store.transaction do
      @store[@user] = tgts
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

  private

  STORED_OBJECTS_FILENAME = 'stodo_data.store'

  def initialize(data_path, user)
    @data_path = data_path
    @user = user
    @stored_fpath = @data_path + File::SEPARATOR + STORED_OBJECTS_FILENAME
    @store = YAML::Store.new(@stored_fpath)
  end

end
