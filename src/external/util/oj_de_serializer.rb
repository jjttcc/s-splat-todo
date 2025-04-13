require 'oj'
require 'ruby_contracts'

class OJDeSerializer
  include Contracts::DSL

  public

  #####  Access

  # The serialized input data
  attr_reader :data

  post :exists_iff_data  do |result| (data != nil) == (result != nil) end
  def result
    if @result.nil? && @data != nil then
      @result = Oj.load(@data)
    end
    @result
  end

  #####  State-changing operations

  # Set 'data' to 'd'.
  post :data do |res, d| self.data == d end
  def data=(d)
    @data = d
    @result = nil
  end

  private

  post :data_set do |result, d| self.data == d end
  def initialize(data = nil)
    @data = data
  end

end
