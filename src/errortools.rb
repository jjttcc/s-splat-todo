module ErrorTools
  public

  def implies(expr1, expr2)
    not expr1 or expr2
  end
end
