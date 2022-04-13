defmodule DaveWeb.WebServerLogStatisticsLiveTest do
  use DaveWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias DaveWeb.Endpoint

  test "can render the page", %{conn: conn} do
    path()

    # live(conn, path())
    get(conn, path())
    |> IO.inspect()

    assert {:ok, _view, _html} = live(conn, path())
  end

  defp path do
    Routes.web_server_log_statistics_path(Endpoint, :show)
  end
end
