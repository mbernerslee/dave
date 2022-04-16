defmodule DaveWeb.RequestStatisticsLiveTest do
  use DaveWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Dave.{
    Constants,
    IncomingWebRequestBuilder,
    RequestStoreStateBuilder,
    RequestPubSub
  }

  alias Dave.Support.DateTimeUtils

  alias DaveWeb.{Endpoint, RequestStatisticsLive}

  test "can render the page", %{conn: conn} do
    assert {:ok, _view, _html} = live(conn, path())
  end

  test "total/1 - counts the total properly" do
    assert RequestStatisticsLive.total([
             %{http_method: "x", path: "x", timestamps: [1, 2, nil]},
             %{http_method: "y", path: "y", timestamps: [4, 5]},
             %{http_method: "z", path: "z", timestamps: [6]}
           ]) == 6
  end

  test "the web_requests can updated when new ones are broadcast view pubsub", %{conn: conn} do
    {:ok, view, _html} = live(conn, path())

    path = IncomingWebRequestBuilder.unique_path()
    http_method = Constants.http_method_get()

    refute view
           |> render()
           |> Floki.find("table")
           |> Floki.text()
           |> Kernel.=~(path)

    request =
      RequestStoreStateBuilder.build_request()
      |> RequestStoreStateBuilder.with_path(path)
      |> RequestStoreStateBuilder.with_http_method(http_method)

    web_requests =
      RequestStoreStateBuilder.build_store()
      |> RequestStoreStateBuilder.add_request(request)

    RequestPubSub.broadcast(web_requests)

    assert view
           |> render()
           |> Kernel.=~(path)

    assert view
           |> render()
           |> Floki.find("table")
           |> Floki.text()
           |> Kernel.=~(path)
  end

  test "by default the all-time filter is active", %{conn: conn} do
    {:ok, view, _html} = live(conn, path())

    %{socket: socket} = :sys.get_state(view.pid)

    assert socket.assigns.active_filter == :all_time
  end

  test "switching filter to something other than all_time, filters what's there", %{conn: conn} do
    ancient = DateTimeUtils.time_ago(:days, 40)
    older = DateTimeUtils.time_ago(:days, 15)
    old = DateTimeUtils.time_ago(:days, 7)
    recent = DateTimeUtils.time_ago(:hours, 12)
    very_recent = DateTimeUtils.time_ago(:miniutes, 15)

    ancient_request =
      RequestStoreStateBuilder.build_request()
      |> RequestStoreStateBuilder.with_incident_timestamp(ancient)

    older_request =
      RequestStoreStateBuilder.build_request()
      |> RequestStoreStateBuilder.with_incident_timestamp(older)

    old_request =
      RequestStoreStateBuilder.build_request()
      |> RequestStoreStateBuilder.with_incident_timestamp(old)

    recent_request =
      RequestStoreStateBuilder.build_request()
      |> RequestStoreStateBuilder.with_incident_timestamp(recent)

    very_recent_request =
      RequestStoreStateBuilder.build_request()
      |> RequestStoreStateBuilder.with_incident_timestamp(very_recent)

    web_requests =
      RequestStoreStateBuilder.build_store()
      |> RequestStoreStateBuilder.add_request(ancient_request)
      |> RequestStoreStateBuilder.add_request(older_request)
      |> RequestStoreStateBuilder.add_request(old_request)
      |> RequestStoreStateBuilder.add_request(recent_request)
      |> RequestStoreStateBuilder.add_request(very_recent_request)

    {:ok, view, _html} = live(conn, path())

    RequestPubSub.broadcast(web_requests)

    assert rendered_total(view) == 5

    expected_counts = %{
      all_time: 5,
      thirty_days: 4,
      ten_days: 3,
      twenty_four_hours: 2,
      thirty_minutes: 1,
      one_min: 0,
      three_seconds: 0
    }

    filters = RequestStatisticsLive.filters()

    Enum.each(filters, fn {filter_name, _} ->
      expected_count = expected_counts[filter_name]

      render_click(view, :filter, %{"value" => to_string(filter_name)})

      assert rendered_total(view) == expected_count
    end)
  end

  test "only the all_time filter shows requests without a timestamp", %{conn: conn} do
    request =
      RequestStoreStateBuilder.build_request()
      |> RequestStoreStateBuilder.with_incident_timestamp(nil)

    web_requests =
      RequestStoreStateBuilder.build_store()
      |> RequestStoreStateBuilder.add_request(request)

    {:ok, view, _html} = live(conn, path())

    RequestPubSub.broadcast(web_requests)

    assert rendered_total(view) == 1

    expected_counts = %{
      all_time: 1,
      thirty_days: 0,
      ten_days: 0,
      twenty_four_hours: 0,
      thirty_minutes: 0,
      one_min: 0,
      three_seconds: 0
    }

    filters = RequestStatisticsLive.filters()

    Enum.each(filters, fn {filter_name, _} ->
      expected_count = expected_counts[filter_name]

      render_click(view, :filter, %{"value" => to_string(filter_name)})

      assert rendered_total(view) == expected_count
    end)
  end

  defp rendered_total(view) do
    view
    |> render()
    |> Floki.find("td#total")
    |> Floki.attribute("value")
    |> hd()
    |> String.to_integer()
  end

  defp path do
    Routes.request_statistics_path(Endpoint, :show)
  end
end
