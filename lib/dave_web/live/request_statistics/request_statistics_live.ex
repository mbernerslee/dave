defmodule DaveWeb.RequestStatisticsLive do
  use DaveWeb, :live_view
  alias Dave.RequestStoreServer
  alias Dave.RequestPubSub

  @all_time "all_time"
  @all_time_atom String.to_atom(@all_time)
  @filters [
    {@all_time_atom, %{seconds: @all_time, text: "All Time"}},
    {:thirty_days, %{seconds: 2_592_000, text: "Last 30 days"}},
    {:ten_days, %{seconds: 864_000, text: "Last 10 days"}},
    {:twenty_four_hours, %{seconds: 86_400, text: "Last 24 hrs"}},
    {:thirty_minutes, %{seconds: 1_800, text: "Last 30 min"}},
    {:one_min, %{seconds: 60, text: "Last 1 min"}}
  ]

  def mount(_, _, socket) do
    if connected?(socket) do
      RequestPubSub.subscribe()
    end

    web_requests = parse_web_requests(RequestStoreServer.read())

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

  def handle_event("filter", %{"value" => @all_time, "name" => @all_time}, socket) do
    web_requests = socket.assigns.web_requests

    socket =
      socket
      |> assign(:active_filter, @all_time_atom)
      |> assign(:filtered_web_requests, web_requests)

    {:noreply, socket}
  end

  def handle_event("filter", %{"value" => seconds, "name" => filter_name}, socket) do
    filter_name = String.to_atom(filter_name)
    seconds = String.to_integer(seconds)

    now = DateTime.utc_now()
    web_requests = socket.assigns.web_requests

    filtered_web_requests =
      Enum.map(web_requests, fn web_request ->
        %{web_request | timestamps: filter_timestamps(web_request.timestamps, seconds, now)}
      end)

    socket =
      socket
      |> assign(:active_filter, filter_name)
      |> assign(:filtered_web_requests, filtered_web_requests)

    {:noreply, socket}
  end

  # TODO it actually needs to periodically update whats in the filter as time moves forward!

  defp filter_timestamps(timestamps, seconds_ago, now) do
    Enum.filter(
      timestamps,
      fn
        nil -> false
        timestamp -> DateTime.diff(now, timestamp) < seconds_ago
      end
    )
  end

  def total(web_requests) do
    Enum.reduce(web_requests, 0, fn %{timestamps: timestamps}, acc ->
      acc + length(timestamps)
    end)
  end

  def filters, do: @filters
  def all_time, do: @all_time

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
