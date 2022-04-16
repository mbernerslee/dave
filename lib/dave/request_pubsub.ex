defmodule Dave.RequestPubSub do
  alias Phoenix.PubSub
  alias Dave.Constants

  @pubsub_topic Constants.pubsub_web_requests_topic()

  def subscribe do
    PubSub.subscribe(Dave.PubSub, @pubsub_topic)
  end

  def broadcast(web_requests) do
    PubSub.broadcast!(Dave.PubSub, @pubsub_topic, {:web_requests, web_requests})
  end
end
