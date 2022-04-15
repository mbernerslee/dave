defmodule Dave.IncomingWebRequestHandler do
  use GenServer
  import Ecto.Query
  alias Dave.{Constants, Repo, IncomingWebRequestLogger}
  alias Dave.IncomingWebRequestPubSub

  @pubsub_topic Constants.pubsub_web_requests_topic()
  @name :incoming_web_request_handler
  @default_options [name: @name]

  def child_spec do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [@default_options]}
    }
  end

  def process_name, do: @name

  def start_link(genserver_options \\ @default_options) do
    GenServer.start_link(__MODULE__, nil, genserver_options)
  end

  def read(pid_or_name \\ @name) do
    GenServer.call(pid_or_name, :read)
  end

  def handle_request(pid_or_name \\ @name, path, http_method) do
    GenServer.cast(pid_or_name, {:new_request, path, http_method})
  end

  @impl true
  def init(_init_arg = nil) do
    web_requests = all_web_requests_from_db()

    IncomingWebRequestPubSub.broadcast(web_requests)
    {:ok, web_requests}
  end

  @impl true
  def handle_call(:read, _from, web_requests) do
    {:reply, web_requests, web_requests}
  end

  @impl true
  def handle_cast({:new_request, path, http_method}, web_requests) do
    case IncomingWebRequestLogger.log(path, http_method) do
      {:ok, %{path: path, http_method: http_method}} ->
        web_requests =
          Map.update(web_requests, %{"http_method" => http_method, "path" => path}, 1, fn count ->
            count + 1
          end)

        IncomingWebRequestPubSub.broadcast(web_requests)

        {:noreply, web_requests}

      :error ->
        {:noreply, web_requests}
    end
  end

  defp all_web_requests_from_db do
    Repo.all(
      from i in "incoming_web_requests",
        inner_join: ii in "incoming_web_request_incidents",
        on: ii.incoming_web_request_id == i.id,
        select: {%{"http_method" => i.http_method, "path" => i.path}, count(ii.id)},
        group_by: [i.http_method, i.path]
    )
    |> Map.new()
  end
end
