defmodule Dave.WebServerLogReader do
  use GenServer

  @default_options [name: :web_server_log_storer]

  def child_spec do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [@default_options]}
    }
  end

  def start_link(genserver_options \\ @default_options) do
    GenServer.start_link(__MODULE__, nil, genserver_options)
  end

  def read(pid_or_name \\ :web_server_log_storer) do
    GenServer.call(pid_or_name, :read)
  end

  @impl true
  def init(_init_arg = nil) do
    web_requests = read_web_requests_from_file()

    Phoenix.PubSub.broadcast!(Dave.PubSub, "web_server_requests", web_requests)
    {:ok, web_requests}
  end

  @impl true
  def handle_call(:read, _from, web_requests) do
    {:reply, web_requests, web_requests}
  end

  @regex ~r|^.*request_id=.*\[.*\] (?<http_verb>[A-Z]+) (?<request_path>[^\s]+).*|

  defp read_web_requests_from_file do
    lines =
      :dave
      |> Application.get_env(:web_server_log_file)
      |> Keyword.fetch!(:location)
      |> File.read!()
      |> String.split("\n")

    Enum.reduce(lines, %{}, fn line, acc ->
      case Regex.named_captures(@regex, line) do
        nil ->
          acc

        request ->
          Map.update(acc, request, 1, fn count -> count + 1 end)
      end
    end)
  end
end
