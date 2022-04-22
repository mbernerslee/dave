defmodule DaveWeb.RequestStatisticsLive do
  use DaveWeb, :live_view
  alias Dave.{RequestPubSub, RequestParser, RequestStoreServer}

  @all_time "all_time"
  @all_time_atom String.to_atom(@all_time)
  @filters [
    {@all_time_atom, %{seconds: @all_time, text: "All Time"}},
    {:thirty_days, %{seconds: 2_592_000, text: "Last 30 days"}},
    {:ten_days, %{seconds: 864_000, text: "Last 10 days"}},
    {:twenty_four_hours, %{seconds: 86_400, text: "Last 24 hrs"}},
    {:thirty_minutes, %{seconds: 1_800, text: "Last 30 min"}},
    {:one_min, %{seconds: 60, text: "Last 1 min"}},
    {:ten_seconds, %{seconds: 10, text: "Last 10 seconds"}},
    {:three_seconds, %{seconds: 3, text: "Last 3 seconds"}}
  ]

  @filters_map Map.new(@filters)

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

    periodically_refresh_filters()

    {:ok, socket}
  end

  def handle_cast(:refresh_filters, socket) do
    socket = refresh_filters(socket)
    periodically_refresh_filters()
    {:noreply, socket}
  end

  def handle_info({:web_requests, web_requests}, socket) do
    web_requests = parse_web_requests(web_requests)

    socket =
      socket
      |> assign(:web_requests, web_requests)
      |> refresh_filters()

    {:noreply, socket}
  end

  def handle_event("filter", %{"value" => @all_time}, socket) do
    web_requests = socket.assigns.web_requests

    socket =
      socket
      |> assign(:active_filter, @all_time_atom)
      |> assign(:filtered_web_requests, web_requests)

    {:noreply, socket}
  end

  def handle_event("filter", %{"value" => filter_name}, socket) do
    filter_name = String.to_atom(filter_name)

    socket =
      socket
      |> assign(:active_filter, filter_name)
      |> refresh_filters()

    {:noreply, socket}
  end

  def total(web_requests) do
    Enum.reduce(web_requests, 0, fn %{timestamps: timestamps}, acc ->
      acc + length(timestamps)
    end)
  end

  def filters, do: @filters
  def all_time, do: @all_time

  defp refresh_filters(socket) do
    %{seconds: seconds} = Map.fetch!(@filters_map, socket.assigns.active_filter)
    web_requests = socket.assigns.web_requests
    filtered_web_requests = RequestParser.filter(web_requests, seconds, DateTime.utc_now())
    assign(socket, :filtered_web_requests, filtered_web_requests)
  end

  defp periodically_refresh_filters do
    pid = self()

    spawn_link(fn ->
      :timer.sleep(1_000)
      GenServer.cast(pid, :refresh_filters)
    end)
  end

  defp parse_web_requests(web_requests) do
    Enum.map(web_requests, fn {%{"http_method" => http_method, "path" => path}, timestamps} ->
      %{http_method: http_method, path: path, timestamps: timestamps}
    end)
  end
end
