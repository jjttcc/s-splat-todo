require 'oj'
require 'ruby_contracts'

class OJSerializer
  include Contracts::DSL

  public

  # The data to be serialized
  attr_reader :data

  # The result of serialization
  def to_s
    Oj.dump(data)
  end

  private

  pre  :data do |data| data != nil end
  post :data_set do |result, d| self.data == d end
  def initialize(data)
    @data = data
  end

end
