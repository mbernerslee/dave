defmodule DaveWeb.WebServerStatisticsLiveTest do
  use DaveWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias Dave.{Constants, IncomingWebRequestBuilder, IncomingWebRequestHandlerStateBuilder}
  alias Dave.IncomingWebRequestPubSub
  alias DaveWeb.Endpoint

  test "can render the page", %{conn: conn} do
    assert {:ok, _view, _html} = live(conn, path())
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

  defp path do
    Routes.web_server_statistics_path(Endpoint, :show)
  end
end
