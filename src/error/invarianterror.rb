require 'assertionerror'

class InvariantError < AssertionError
  def initialize(msg="")
    super(msg)
  end

  def prefix
    "InvariantError"
  end

end
