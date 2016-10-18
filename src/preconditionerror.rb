require_relative 'assertionerror'

class PreconditionError < AssertionError
  def initialize(msg="")
    super(msg)
  end

  def prefix
    ""
  end

end
