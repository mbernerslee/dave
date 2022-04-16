defmodule Dave.RequestStoreServerTest do
  use Dave.DataCase, async: false
  # has to be async: false, because how how test-spawned PIDs sharing a database connection works
  # doesn't "have to be", but alternatives seemed nasty at the time

  alias Phoenix.PubSub

  alias Dave.{
    Constants,
    RequestStoreServer,
    IncomingWebRequestBuilder,
    IncomingWebRequestIncidentBuilder
  }

  alias Dave.Support.DateTimeUtils

  @pubsub_topic Constants.pubsub_web_requests_topic()

  describe "start_link/1" do
    test "on startup, loads the current web requests from the DB into memory" do
      %{path: path_1, http_method: http_method_1, id: incoming_web_request_id_1} =
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.insert(
          insert_incident: false,
          returning: [:path, :http_method]
        )

      %{path: path_2, http_method: http_method_2, id: incoming_web_request_id_2} =
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.insert(
          insert_incident: false,
          returning: [:path, :http_method]
        )

      %{path: path_3, http_method: http_method_3, id: incoming_web_request_id_3} =
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.insert(
          insert_incident: false,
          returning: [:path, :http_method]
        )

      now = %{DateTime.utc_now() | microsecond: {0, 0}}
      before = %{DateTime.add(now, -10_000) | microsecond: {0, 0}}
      long_ago = %{DateTime.add(now, -100_000) | microsecond: {0, 0}}
      ancient = %{DateTime.add(now, -1_000_000) | microsecond: {0, 0}}

      IncomingWebRequestIncidentBuilder.build()
      |> IncomingWebRequestIncidentBuilder.with_incoming_web_request_id(incoming_web_request_id_1)
      |> IncomingWebRequestIncidentBuilder.with_timestamps(ancient)
      |> IncomingWebRequestIncidentBuilder.insert()

      IncomingWebRequestIncidentBuilder.build()
      |> IncomingWebRequestIncidentBuilder.with_incoming_web_request_id(incoming_web_request_id_1)
      |> IncomingWebRequestIncidentBuilder.with_timestamps(long_ago)
      |> IncomingWebRequestIncidentBuilder.insert()

      IncomingWebRequestIncidentBuilder.build()
      |> IncomingWebRequestIncidentBuilder.with_incoming_web_request_id(incoming_web_request_id_2)
      |> IncomingWebRequestIncidentBuilder.with_timestamps(before)
      |> IncomingWebRequestIncidentBuilder.insert()

      IncomingWebRequestIncidentBuilder.build()
      |> IncomingWebRequestIncidentBuilder.with_incoming_web_request_id(incoming_web_request_id_2)
      |> IncomingWebRequestIncidentBuilder.with_timestamps(now)
      |> IncomingWebRequestIncidentBuilder.insert()

      IncomingWebRequestIncidentBuilder.build()
      |> IncomingWebRequestIncidentBuilder.with_incoming_web_request_id(incoming_web_request_id_3)
      |> IncomingWebRequestIncidentBuilder.without_timestamps()
      |> IncomingWebRequestIncidentBuilder.insert()

      {:ok, pid} = RequestStoreServer.start_link([])

      assert %{
               %{"http_method" => ^http_method_1, "path" => ^path_1} => [
                 actual_long_ago,
                 actual_ancient
               ],
               %{"http_method" => ^http_method_2, "path" => ^path_2} => [
                 actual_now,
                 actual_before
               ],
               %{"http_method" => ^http_method_3, "path" => ^path_3} => [nil]
             } = :sys.get_state(pid)

      assert DateTimeUtils.within_a_second?(actual_long_ago, long_ago)
      assert DateTimeUtils.within_a_second?(actual_ancient, ancient)
      assert DateTimeUtils.within_a_second?(actual_now, now)
      assert DateTimeUtils.within_a_second?(actual_before, before)
    end

    test "broadcasts the web_requests" do
      %{path: path, http_method: http_method} =
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.insert(returning: [:path, :http_method])

      PubSub.subscribe(Dave.PubSub, @pubsub_topic)

      {:ok, _} = RequestStoreServer.start_link([])

      assert_received {:web_requests, %{%{"http_method" => ^http_method, "path" => ^path} => [_]}}
    end
  end

  describe "read/1" do
    test "returns the web_requests stored in the genserver state" do
      %{path: path_1, http_method: http_method_1} =
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.insert(returning: [:path, :http_method])

      %{path: path_2, http_method: http_method_2} =
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.insert(returning: [:path, :http_method])

      {:ok, pid} = RequestStoreServer.start_link([])

      assert %{
               %{"http_method" => ^http_method_1, "path" => ^path_1} => [_],
               %{"http_method" => ^http_method_2, "path" => ^path_2} => [_]
             } = RequestStoreServer.read(pid)
    end
  end

  describe "handle_request/3" do
    test "given a previously unseen request, updates the state with the new request" do
      %{path: path_1, http_method: http_method_1} =
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.insert(returning: [:path, :http_method])

      new_path = IncomingWebRequestBuilder.unique_path()
      new_http_method = Constants.http_method_get()

      {:ok, pid} = RequestStoreServer.start_link([])

      assert RequestStoreServer.handle_request(pid, new_path, new_http_method) == :ok

      assert %{
               %{"http_method" => ^http_method_1, "path" => ^path_1} => [_],
               %{"http_method" => ^new_http_method, "path" => ^new_path} => [_]
             } = :sys.get_state(pid)
    end

    test "given a previously seen request coming in again, updates the state" do
      %{path: path, http_method: http_method} =
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.insert(returning: [:path, :http_method])

      {:ok, pid} = RequestStoreServer.start_link([])

      assert RequestStoreServer.handle_request(pid, path, http_method) == :ok

      assert %{%{"http_method" => ^http_method, "path" => ^path} => [_, _]} = :sys.get_state(pid)

      assert RequestStoreServer.handle_request(pid, path, http_method) == :ok

      assert %{%{"http_method" => ^http_method, "path" => ^path} => [_, _, _]} =
               :sys.get_state(pid)
    end

    test "broadcasts the updated web_requests" do
      {:ok, pid} = RequestStoreServer.start_link([])

      path = IncomingWebRequestBuilder.unique_path()
      http_method = Constants.http_method_get()

      PubSub.subscribe(Dave.PubSub, @pubsub_topic)

      assert RequestStoreServer.handle_request(pid, path, http_method) == :ok

      assert_receive {:web_requests, %{%{"http_method" => ^http_method, "path" => ^path} => [_]}}
    end
  end
end
