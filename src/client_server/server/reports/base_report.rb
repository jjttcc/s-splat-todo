class BaseReport
  attr_reader :database, :message, :recursive, :short_format

  def initialize(database, recursive = false, short_format = false)
    @database = database
    @message = ""
    @recursive = recursive
    @short_format = short_format
  end

  # Abstract method to be implemented by subclasses
  def report(criteria, recursive = false)
    raise NotImplementedError, "Subclasses must implement this method"
  end

  protected

  def set_message(msg)
    @message = msg
  end
end
