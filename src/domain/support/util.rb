require 'ruby_contracts'

# Utility functionality
module Util
  include Contracts::DSL

  public

  #####  Boolean queries

  # Is the specified string 's' a valid integer?
  post :false_if_empty do |result, s|
    implies(s.nil? || ! s.is_a?(String) || s.empty?, ! result) end
  def is_i?(s)
    s != nil && s.is_a?(String) && /\A[-+]?\d+\z/ === s
  end

  #####  Basic operations

  # Assert the 'boolean_expression' is true - raise 'msg' if it is false.
  def check(boolean_expression, msg = nil)
    if msg.nil? then
      msg = "false assertion: '#{caller_locations(1, 1)[0].label}'"
    end
    if ! boolean_expression then
      raise msg
    end
  end

end
