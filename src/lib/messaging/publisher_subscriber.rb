require_relative 'publication'
require_relative 'subscription'

class PublisherSubscriber
  include Contracts::DSL, Publication, Subscription

  private

  post :channels_set do
    ! (default_publishing_channel.nil? || default_subscription_channel.nil?) end
  def initialize(pubchan = 'default-pub-channel',
                 subchan = 'default-sub-channel')
    init_pubsub(default_pubchan: pubchan, default_subchan: subchan)
  end

  post :channels_set do
    ! (default_publishing_channel.nil? || default_subscription_channel.nil?) end
  def init_pubsub(default_pubchan: 'default-pub-channel',
                  default_subchan: 'default-sub-channel')
    @default_publishing_channel = default_pubchan
    @default_subscription_channel = default_subchan
  end

end
