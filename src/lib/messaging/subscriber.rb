require 'ruby_contracts'
require_relative 'subscription'

class Subscriber
  include Contracts::DSL, Subscription

  def initialize(subchan = 'default-channel')
    @default_subscription_channel = subchan
  end

end
