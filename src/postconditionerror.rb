require_relative 'assertionerror'

class PostconditionError < AssertionError
  def initialize(msg="")
    super(msg)
  end

  def prefix
    ""
  end

end
