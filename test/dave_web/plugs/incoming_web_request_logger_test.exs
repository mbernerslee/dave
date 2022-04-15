defmodule DaveWeb.Plugs.IncomingWebRequestLoggerTest do
  use DaveWeb.ConnCase, async: false
  import Ecto.Query
  alias Dave.{Constants, IncomingWebRequestHandler, Repo}
  alias DaveWeb.Endpoint
  alias DaveWeb.Plugs.IncomingWebRequestLogger

  test "informs the IncomingWebRequestHandler of the request", %{conn: conn} do
    {:ok, pid} = IncomingWebRequestHandler.start_link([])

    assert :sys.get_state(pid) == %{}

    path = arbitrary_existant_path()
    conn = %{conn | request_path: path, method: Constants.http_method_get()}

    IncomingWebRequestLogger.call(conn, pid)

    assert :sys.get_state(pid) == %{
             %{"http_method" => Constants.http_method_get(), "path" => path} => 1
           }
  end

  test "hitting an arbitrary existant path, stores it in the database", %{conn: conn} do
    path = arbitrary_existant_path()

    assert web_requests_in_db() == []

    get(conn, path)

    assert web_requests_in_db() == [{"GET", path, 1}]
  end

  test "hitting an arbitrary NON existant path, stores it in the database", %{conn: conn} do
    path = "/totally-not-a-real-path"

    assert web_requests_in_db() == []

    assert_raise Phoenix.Router.NoRouteError, fn -> get(conn, path) end

    assert web_requests_in_db() == [{"GET", path, 1}]
  end

  defp web_requests_in_db do
    Repo.all(
      from i in "incoming_web_requests",
        inner_join: ii in "incoming_web_request_incidents",
        on: ii.incoming_web_request_id == i.id,
        group_by: [i.http_method, i.path],
        select: {i.http_method, i.path, count(ii.id)}
    )
  end

  defp arbitrary_existant_path do
    Routes.web_server_statistics_path(Endpoint, :show)
  end
end
