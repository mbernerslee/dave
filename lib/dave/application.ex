defmodule Dave.Application do
  alias Dave.RequestStoreServer
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    mandatory_children = [
      DaveWeb.Telemetry,
      {Phoenix.PubSub, name: Dave.PubSub},
      DaveWeb.Endpoint,
      Dave.Repo,
      RequestStoreServer.child_spec()
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dave.Supervisor]
    Supervisor.start_link(mandatory_children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DaveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
