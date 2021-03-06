defmodule DaveWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use DaveWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import DaveWeb.ConnCase

      alias DaveWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint DaveWeb.Endpoint
    end
  end

  @host Application.compile_env(:dave, DaveWeb.Endpoint)[:url][:host]

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Dave.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    # set the "host" for the request properly, so that Plug.SSL can be told to exclude forcing HTTPS upgrade in test mode only
    # see config :dave, Endpoint - force_ssl exlucde in config/config.exs vs config/test.exs
    # this stops enforcing HTTPS but only in the test env, and only for @host
    conn = %{Phoenix.ConnTest.build_conn() | host: @host}

    {:ok, conn: conn}
  end
end
