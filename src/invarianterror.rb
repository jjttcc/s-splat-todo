require_relative 'assertionerror'

class InvariantError < AssertionError
  def initialize(msg="")
    super(msg)
  end

  def prefix
    ""
  end

end
