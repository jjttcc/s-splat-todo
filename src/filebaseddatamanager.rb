class FileBasedDataManager

  public

  # Add each element of `handles' to the handles file.
  def add_handles(handles)
    if not handles.empty? then
      hfile = File.new(@handle_fpath, "a")
      hfile.write(handles.join("\n") + "\n")
    end
  end

  # A hash table of the currently stored handles, where each handle is a
  # key and the associated value is true
  def stored_handles
      handles = File.read @handle_fpath
      Hash[handles.split("\n").map {|h| [h, true]}]
  end

  private

  HANDLE_FILENAME = 'stodo_handles'

  def initialize(data_path)
    @data_path = data_path
    @handle_fpath = @data_path + File::SEPARATOR + HANDLE_FILENAME
  end

end
