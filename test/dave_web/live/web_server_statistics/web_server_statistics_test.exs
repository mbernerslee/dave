defmodule DaveWeb.WebServerStatisticsLiveTest do
  use DaveWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias Dave.{Constants, IncomingWebRequestBuilder, IncomingWebRequestHandler}
  alias DaveWeb.Endpoint

  # TODO rename the log stats module (this one)
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

    # TODO split subscribing & broadcasting out of there into separate module
    # TODO make a builder for the server state of Handler
    IncomingWebRequestHandler.broadcast(%{
      %{"http_method" => http_method, "path" => path} => 1
    })

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
