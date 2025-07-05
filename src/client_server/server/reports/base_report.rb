class BaseReport
  attr_reader :database, :fail_msg

  def initialize(database)
    @database = database
    @fail_msg = ""
  end

  # Abstract method to be implemented by subclasses
  def generate_report(criteria)
    raise NotImplementedError, "Subclasses must implement this method"
  end

  protected

  def set_fail_msg(msg)
    @fail_msg = msg
  end
end
