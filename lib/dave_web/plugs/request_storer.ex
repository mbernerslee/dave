defmodule DaveWeb.Plugs.RequestStorer do
  alias Dave.RequestStoreServer

  @handler_name RequestStoreServer.process_name()

  def init(opts) do
    Keyword.get(opts, :handler_pid_or_name, @handler_name)
  end

  def call(conn, handler_pid_or_name) do
    RequestStoreServer.handle_request(
      handler_pid_or_name,
      conn.request_path,
      conn.method
    )

    conn
  end
end
