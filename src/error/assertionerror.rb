class AssertionError < RuntimeError
  private

  def initialize(msg="")
    super(prefix + msg)
  end

  def prefix
    "assertion violation: "
  end
end
