require 'assertionerror'

class PreconditionError < AssertionError
  def initialize(msg="")
    super(msg)
  end

  def prefix
    "PreconditionError"
  end

end
