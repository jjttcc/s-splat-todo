require 'assertionerror'

class PostconditionError < AssertionError
  def initialize(msg="")
    super(msg)
  end

  def prefix
    "PostconditionError"
  end

end
