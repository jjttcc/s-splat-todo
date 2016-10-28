require_relative 'preconditionerror'
require_relative 'postconditionerror'
require_relative 'invarianterror'

module ErrorTools
  public

  def implies(expr1, expr2)
    not expr1 or expr2
  end

  def assert &block
    raise AssertionError unless yield
  end

  def assert_invariant(msg = "", &block)
    if ! yield then
      trace = caller.join("\n")
      raise InvariantError, msg, [block.source_location.to_s, trace]
    end
  end

  def assert_precondition(msg = "", &block)
    if ! yield then
      trace = caller.join("\n")
      raise PreconditionError, msg, [block.source_location.to_s, trace]
    end
  end

  def assert_postcondition(msg = "", &block)
    if ! yield then
      trace = caller.join("\n")
      raise PostconditionError, msg, [block.source_location.to_s, trace]
    end
  end

end
