defmodule DaveWeb.Plugs.IncomingWebRequestPersisterTest do
  use DaveWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "hitting an arbitrary existant route, stores it in the database", %{conn: conn} do
    # TODO this properly
    Routes.web_server_log_statistics_path(conn, :show)
    |> IO.inspect()

    live(conn, "/")
    |> IO.inspect(limit: :infinity)
  end
end
