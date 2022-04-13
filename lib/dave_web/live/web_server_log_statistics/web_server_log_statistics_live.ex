defmodule DaveWeb.WebServerLogStatisticsLive do
  use DaveWeb, :live_view
  alias Dave.WebServerLogReader

  def mount(_, _, socket) do
    IO.inspect("hit it!")
    web_requests = parse(WebServerLogReader.read())

    socket = assign(socket, :web_requests, web_requests)
    {:ok, socket}
  end

  def parse(web_requests) do
    web_requests
    |> Enum.map(fn {%{"http_verb" => http_verb, "request_path" => request_path}, count} ->
      %{http_verb: http_verb, request_path: request_path, count: count}
    end)
    |> Enum.sort_by(& &1.http_verb, :asc)
    |> Enum.sort_by(& &1.request_path, :asc)
    |> Enum.sort_by(& &1.count, :desc)
  end
end
