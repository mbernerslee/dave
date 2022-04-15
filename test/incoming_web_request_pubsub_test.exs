defmodule Dave.IncomingWebRequestPubSubTest do
  use ExUnit.Case, async: true
  alias Phoenix.PubSub
  alias Dave.{Constants, IncomingWebRequestPubSub}

  @pubsub_topic Constants.pubsub_web_requests_topic()

  describe "subscribe/0" do
    test "means your process recieves the pubsub messages" do
      IncomingWebRequestPubSub.subscribe()

      PubSub.broadcast!(Dave.PubSub, @pubsub_topic, {:web_requests, "cool message!"})

      assert_receive {:web_requests, "cool message!"}
    end
  end

  describe "broadcast/0" do
    test "subscribers get the message!" do
      PubSub.subscribe(Dave.PubSub, @pubsub_topic)

      IncomingWebRequestPubSub.broadcast("cool message!")

      assert_receive {:web_requests, "cool message!"}
    end
  end
end
