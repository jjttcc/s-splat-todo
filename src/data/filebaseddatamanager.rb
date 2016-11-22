# !!!!To-do: lock the persistent store file.
class FileBasedDataManager

  public

  # Write `tgts' out to persistent store.
  def store_targets(tgts)
    serialized_object = Marshal::dump(tgts)
    out = File.new(@stored_fpath, 'w')
    out.write(serialized_object)
  end

  # "STodoTarget"s restored from persistent store.
  def restored_targets
    result = {}
    begin
      infile = File.new(@stored_fpath, 'r')
    rescue SystemCallError => e
      if e.class.name.start_with?('Errno::ENOENT') then
        $log.debug e.message
      else
        raise e
      end
    end
    if infile != nil then
      data = infile.read
      result = Marshal.load(data)
    end
    result
  end


  private

  STORED_OBJECTS_FILENAME = 'stodo_data'

  def initialize(data_path)
    @data_path = data_path
    @stored_fpath = @data_path + File::SEPARATOR + STORED_OBJECTS_FILENAME
  end

end
