class BaseReport
  attr_reader :database, :message, :recursive

  def initialize(database, recursive = false)
    @database = database
    @message = ""
    @recursive = recursive
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
