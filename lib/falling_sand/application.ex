defmodule FallingSand.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  @size Application.compile_env(:falling_sand, :size)
  alias FallingSand.Grid

  use Application

  @impl true
  def start(_type, _args) do
    grid =
      Grid.new(name: :grid, min: 0, max: Application.get_env(:falling_sand, :grid_size))

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
          do: [],
          else: [{FallingSand.GridServer, [grid: grid, name: FallingSand.GridServer]}]

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
