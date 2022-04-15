defmodule DaveWeb.WebServerStatisticsLive do
  use DaveWeb, :live_view
  alias Dave.IncomingWebRequestHandler

  # TODO rename this module
  def mount(_, _, socket) do
    if connected?(socket) do
      IncomingWebRequestHandler.subscribe()
    end

    web_requests = parse(IncomingWebRequestHandler.read())

    socket = assign(socket, :web_requests, web_requests)
    {:ok, socket}
  end

  def handle_info({:web_requests, web_requests}, socket) do
    web_requests = parse(web_requests)
    socket = assign(socket, :web_requests, web_requests)
    {:noreply, socket}
  end

  defp parse(web_requests) do
    web_requests
    |> Enum.map(fn {%{"http_method" => http_method, "path" => path}, count} ->
      %{http_method: http_method, path: path, count: count}
    end)
    |> Enum.sort_by(& &1.http_method, :asc)
    |> Enum.sort_by(& &1.path, :asc)
    |> Enum.sort_by(& &1.count, :desc)
  end
end
