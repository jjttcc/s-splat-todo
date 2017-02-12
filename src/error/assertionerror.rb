class AssertionError < RuntimeError
  private

  def initialize(msg="")
    super(prefix + msg + suffix)
  end

  def prefix
    "assertion violation: "
  end

  def suffix
    "\n[backtrace:\n" + caller.join("\n") + ']'
  end
end
