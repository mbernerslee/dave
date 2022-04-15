defmodule Dave.IncomingWebRequestHandlerTest do
  use Dave.DataCase, async: false
  # has to be async: false, because how how test-spawned PIDs sharing a database connection works
  # doesn't "have to be", but alternatives seemed nasty at the time

  alias Phoenix.PubSub

  alias Dave.{
    Constants,
    IncomingWebRequestHandler,
    IncomingWebRequestBuilder,
    IncomingWebRequestIncidentBuilder
  }

  @pubsub_topic Constants.pubsub_web_requests_topic()

  describe "start_link/1" do
    test "on startup, loads the current web requests from the DB into memory" do
      %{path: path_1, http_method: http_method_1} =
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.insert(returning: [:path, :http_method])

      %{path: path_2, http_method: http_method_2, id: incoming_web_request_id_2} =
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.insert(returning: [:path, :http_method])

      IncomingWebRequestIncidentBuilder.build()
      |> IncomingWebRequestIncidentBuilder.with_incoming_web_request_id(incoming_web_request_id_2)
      |> IncomingWebRequestIncidentBuilder.insert()

      {:ok, pid} = IncomingWebRequestHandler.start_link([])

      assert %{
               %{"http_method" => http_method_1, "path" => path_1} => 1,
               %{"http_method" => http_method_2, "path" => path_2} => 2
             } == :sys.get_state(pid)
    end

    test "broadcasts the web_requests" do
      %{path: path, http_method: http_method} =
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.insert(returning: [:path, :http_method])

      PubSub.subscribe(Dave.PubSub, @pubsub_topic)

      {:ok, _} = IncomingWebRequestHandler.start_link([])

      assert_received {:web_requests, %{%{"http_method" => ^http_method, "path" => ^path} => 1}}
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

      {:ok, pid} = IncomingWebRequestHandler.start_link([])

      assert %{
               %{"http_method" => http_method_1, "path" => path_1} => 1,
               %{"http_method" => http_method_2, "path" => path_2} => 1
             } == IncomingWebRequestHandler.read(pid)
    end
  end

  describe "handle_request/3" do
    test "given a previously unseen request, updates the state with the new request" do
      %{path: path_1, http_method: http_method_1} =
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.insert(returning: [:path, :http_method])

      new_path = IncomingWebRequestBuilder.unique_path()
      new_http_method = Constants.http_method_get()

      {:ok, pid} = IncomingWebRequestHandler.start_link([])

      assert IncomingWebRequestHandler.handle_request(pid, new_path, new_http_method) == :ok

      assert %{
               %{"http_method" => http_method_1, "path" => path_1} => 1,
               %{"http_method" => new_http_method, "path" => new_path} => 1
             } == :sys.get_state(pid)
    end

    test "given a previously seen request coming in again, updates the state" do
      %{path: path, http_method: http_method} =
        IncomingWebRequestBuilder.build()
        |> IncomingWebRequestBuilder.insert(returning: [:path, :http_method])

      {:ok, pid} = IncomingWebRequestHandler.start_link([])

      assert IncomingWebRequestHandler.handle_request(pid, path, http_method) == :ok

      assert %{%{"http_method" => http_method, "path" => path} => 2} == :sys.get_state(pid)

      assert IncomingWebRequestHandler.handle_request(pid, path, http_method) == :ok

      assert %{%{"http_method" => http_method, "path" => path} => 3} == :sys.get_state(pid)
    end

    test "broadcasts the updated web_requests" do
      {:ok, pid} = IncomingWebRequestHandler.start_link([])

      path = IncomingWebRequestBuilder.unique_path()
      http_method = Constants.http_method_get()

      PubSub.subscribe(Dave.PubSub, @pubsub_topic)

      assert IncomingWebRequestHandler.handle_request(pid, path, http_method) == :ok

      assert_receive {:web_requests, %{%{"http_method" => ^http_method, "path" => ^path} => 1}}
    end
  end
end
