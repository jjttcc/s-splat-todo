require 'preconditionerror'
require 'postconditionerror'
require 'invarianterror'

module ErrorTools
  public

  # Mathematical implication function - i.e.: expr implies expr2
  def implies(expr1, expr2)
    ! expr1 or expr2
  end

  # Same as 'implies', but with 'expr2' "eval"d as a string in order to
  # avoid runtime errors (such as: undefined method `length' for nil:NilClass)
  # that can occur when 'implies' is called with expr1 == false, such that
  # 'expr2', even though it wouldn't be evaluated here due to the
  # short-circuiting nature of "or", is evaluated before being passed as
  # an argument - e.g., where 'expr2' is self.foo.length and self.foo
  # is nil.
  def implies_eval2(expr1, expr2)
    ! expr1 or eval expr2
  end

  def assert(msg = "", &block)
    if ! yield then
      trace = caller.join("\n")
      raise AssertionError, ": #{msg}", [block.source_location.to_s, trace]
    end
  end

  alias_method :check, :assert

  def assert_invariant(msg = "", &block)
    if ! yield then
      trace = caller.join("\n")
      raise InvariantError, ": #{msg}", [block.source_location.to_s, trace]
    end
  end

  def assert_precondition(msg = "", &block)
    if ! yield then
      trace = caller.join("\n")
      raise PreconditionError, ": #{msg}", [block.source_location.to_s, trace]
    end
  end

  def assert_postcondition(msg = "", &block)
    if ! yield then
      trace = caller.join("\n")
      raise PostconditionError, ": #{msg}", [block.source_location.to_s, trace]
    end
  end

end
