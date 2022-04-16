defmodule DaveWeb.WebServerStatisticsLive do
  use DaveWeb, :live_view
  alias Dave.IncomingWebRequestHandler
  alias Dave.IncomingWebRequestPubSub

  @filters_with_seconds [
    %{name: :thirty_days, text: "Last 30 days", seconds: 2_592_000},
    %{name: :ten_days, text: "Last 10 days", seconds: 864_000},
    %{name: :twenty_four_hours, text: "Last 24 hrs", seconds: 86_400},
    %{name: :thirty_minutes, text: "Last 30 min", seconds: 1_800},
    %{name: :one_min, text: "Last 1 min", seconds: 60}
  ]

  @all_time_filter %{name: :all_time, text: "All Time", seconds: ""}
  @all_time @all_time_filter.name
  @all_time_string to_string(@all_time)

  @filters [@all_time_filter | @filters_with_seconds]

  def mount(_, _, socket) do
    if connected?(socket) do
      IncomingWebRequestPubSub.subscribe()
    end

    web_requests = parse_web_requests(IncomingWebRequestHandler.read())

    socket =
      socket
      |> assign(:web_requests, web_requests)
      |> assign(:filtered_web_requests, web_requests)
      |> assign(:active_filter, :all_time)

    {:ok, socket}
  end

  def handle_info({:web_requests, web_requests}, socket) do
    # TODO filter web_requests as they come in too
    web_requests = parse_web_requests(web_requests)

    socket =
      socket
      |> assign(:web_requests, web_requests)
      |> assign(:filtered_web_requests, web_requests)

    {:noreply, socket}
  end

  def handle_event(@all_time_string, %{"value" => ""}, socket) do
    socket = assign(socket, :active_filter, @all_time)
    filter(socket, @all_time, nil)
  end

  @filters_with_seconds
  |> Enum.each(fn %{name: filter_name, seconds: seconds} ->
    def handle_event(unquote(Atom.to_string(filter_name)), %{"value" => _seconds}, socket) do
      filter(socket, unquote(filter_name), unquote(seconds))
    end
  end)

  # TODO add a test for when timestamp is nil
  defp filter(socket, active_filter, seconds) do
    now = DateTime.utc_now()

    filtered_web_requests =
      Enum.map(socket.assigns.web_requests, fn web_request ->
        %{web_request | timestamps: filter_timestamps(web_request.timestamps, seconds, now)}
      end)

    socket =
      socket
      |> assign(:active_filter, active_filter)
      |> assign(:filtered_web_requests, filtered_web_requests)

    {:noreply, socket}
  end

  defp filter_timestamps(timestamps, seconds_ago, now) do
    Enum.filter(timestamps, fn timestamp ->
      DateTime.diff(now, timestamp) < seconds_ago
    end)
  end

  def total(web_requests) do
    Enum.reduce(web_requests, 0, fn %{timestamps: timestamps}, acc ->
      acc + length(timestamps)
    end)
  end

  def filters, do: @filters

  defp parse_web_requests(web_requests) do
    web_requests
    |> Enum.map(fn {%{"http_method" => http_method, "path" => path}, timestamps} ->
      %{http_method: http_method, path: path, timestamps: timestamps}
    end)
    |> Enum.sort_by(& &1.http_method, :asc)
    |> Enum.sort_by(& &1.path, :asc)
    |> Enum.sort_by(&length(&1.timestamps), :desc)
  end
end
