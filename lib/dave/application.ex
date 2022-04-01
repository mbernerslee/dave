defmodule Dave.Application do
  alias Dave.WebServerLogReader
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
      WebServerLogReader.child_spec()
    ]

    optional_children = if use_the_database?(), do: [Dave.Repo], else: []

    children = mandatory_children ++ optional_children

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dave.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp use_the_database? do
    :dave
    |> Application.get_env(Dave.Repo)
    |> Keyword.fetch!(:use_it)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DaveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
