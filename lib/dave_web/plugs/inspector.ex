defmodule DaveWeb.Plugs.Inspector do
  def init(opts), do: opts

  def call(conn, _opts) do
    IO.inspect(conn.halted, label: "HERE!")
    conn
  end
end
