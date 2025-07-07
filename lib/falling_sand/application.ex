defmodule FallingSand.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  alias FallingSand.Grid

  use Application

  @impl true
  def start(_type, _args) do
    grid = Grid.new(name: Grid)

    children =
      [
        FallingSandWeb.Telemetry,
        {DNSCluster, query: Application.get_env(:falling_sand, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: FallingSand.PubSub},
        # Start the Finch HTTP client for sending emails
        {Finch, name: FallingSand.Finch},
        # Start a worker by calling: FallingSand.Worker.start_link(arg)
        # {FallingSand.Worker, arg},
        # Start to serve requests, typically the last entry

        FallingSandWeb.Endpoint
      ] ++
        if Mix.env() == :test,
          do: [
            {FallingSand.Tracker, [name: FallingSand.Tracker, pubsub_server: FallingSand.PubSub]}
          ],
          else: [{FallingSand.TickServer, [grid: grid, name: FallingSand.TickServer]}]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FallingSand.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FallingSandWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
