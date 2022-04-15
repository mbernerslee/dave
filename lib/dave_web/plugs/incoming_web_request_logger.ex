defmodule DaveWeb.Plugs.IncomingWebRequestLogger do
  alias Dave.IncomingWebRequestHandler

  @handler_name IncomingWebRequestHandler.process_name()

  def init(opts) do
    Keyword.get(opts, :handler_pid_or_name, @handler_name)
  end

  def call(conn, handler_pid_or_name) do
    IncomingWebRequestHandler.handle_request(
      handler_pid_or_name,
      conn.request_path,
      conn.method
    )

    conn
  end
end
