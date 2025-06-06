require 'ruby_contracts'
require_relative 'publication'

class Publisher
  include Contracts::DSL, Publication

  private

  def initialize(pubchan = 'default-channel')
    @default_publishing_channel = pubchan
  end

end
