defmodule DaveWeb.WebServerStatisticsLiveTest do
  use DaveWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Dave.{
    Constants,
    IncomingWebRequestBuilder,
    IncomingWebRequestHandlerStateBuilder,
    IncomingWebRequestPubSub
  }

  alias Dave.Support.DateTimeUtils

  alias DaveWeb.{Endpoint, WebServerStatisticsLive}

  test "can render the page", %{conn: conn} do
    assert {:ok, _view, _html} = live(conn, path())
  end

  test "total/1 - counts the total properly" do
    assert WebServerStatisticsLive.total([
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

    web_requests =
      IncomingWebRequestHandlerStateBuilder.build()
      |> IncomingWebRequestHandlerStateBuilder.add_incident_with_path_and_http_method(
        path,
        http_method
      )

    IncomingWebRequestPubSub.broadcast(web_requests)

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

    web_requests =
      IncomingWebRequestHandlerStateBuilder.build()
      |> IncomingWebRequestHandlerStateBuilder.add_incident_with_path_and_http_method(
        "x",
        "y",
        ancient
      )
      |> IncomingWebRequestHandlerStateBuilder.add_incident_with_path_and_http_method(
        "x",
        "y",
        older
      )
      |> IncomingWebRequestHandlerStateBuilder.add_incident_with_path_and_http_method(
        "x",
        "y",
        old
      )
      |> IncomingWebRequestHandlerStateBuilder.add_incident_with_path_and_http_method(
        "x",
        "y",
        recent
      )
      |> IncomingWebRequestHandlerStateBuilder.add_incident_with_path_and_http_method(
        "x",
        "y",
        very_recent
      )

    {:ok, view, _html} = live(conn, path())

    IncomingWebRequestPubSub.broadcast(web_requests)

    assert rendered_total(view) == 5

    expected_counts = [5, 4, 3, 2, 1]

    WebServerStatisticsLive.filters()
    |> Enum.zip(expected_counts)
    # |> Enum.each(fn {{filter, _, seconds}, expected_count} ->
    |> Enum.each(fn {%{name: filter, seconds: seconds}, expected_count} ->
      render_click(view, to_string(filter), %{"value" => seconds})

      assert rendered_total(view) == expected_count
    end)
  end

  # add test for filtering when timestamp = nil

  defp rendered_total(view) do
    view
    |> render()
    |> Floki.find("td#total")
    |> Floki.attribute("value")
    |> hd()
    |> String.to_integer()
  end

  defp path do
    Routes.web_server_statistics_path(Endpoint, :show)
  end
end
