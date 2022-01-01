defmodule DaveWeb.PageController do
  use DaveWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
