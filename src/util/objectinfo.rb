require 'ruby_contracts'

# Instances of this class provide information about a specific
# object, such as the public methods of the class the object belongs to.
# One use of this class is as a debugging tool.
class ObjectInfo
  include Contracts::DSL

  public

  attr_accessor :object

  # object's public methods, excluding inherited methods
  def pub_m
    object.public_methods(false)
  end

  # object's public methods, including inherited methods
  def allpub_m
    object.public_methods(true)
  end

  # object's private methods, excluding inherited methods
  def priv_m
    object.private_methods(false)
  end

  # object's private methods, including inherited methods
  def allpriv_m
    object.private_methods(true)
  end

  # object's protected methods, excluding inherited methods
  def prot_m
    object.protected_methods(false)
  end

  # object's protected methods, including inherited methods
  def allprot_m
    object.protected_methods(true)
  end

  # object's attributes (AKA instance variables)
  def attrs
    object.instance_variables
  end

  # the value of each of object's attributes
  def attr_vs
    object.instance_variables.map do |o|
      symbol = o.to_s
      name = symbol[1..-1]
      begin
        "#{name}: #{object.method(name).()}"
      rescue => e
      end
    end
  end

  private

  pre :obj_exists do |o| ! o.nil? end
  def initialize(o)
    self.object = o
  end

end
