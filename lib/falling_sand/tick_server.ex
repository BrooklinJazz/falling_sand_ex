defmodule FallingSand.TickServer do
  alias FallingSand.Grid
  use GenServer

  @interval Application.compile_env!(:falling_sand, :tick_interval)
  @pubsub_topic "grid"

  def start_link(opts) do
    interval = Keyword.get(opts, :tick, @interval)
    name = Keyword.get(opts, :name)
    grid = Keyword.fetch!(opts, :grid)
    GenServer.start_link(__MODULE__, [interval: interval, grid: grid], name: name)
  end

  def init(opts) do
    interval = Keyword.get(opts, :interval)
    grid = Keyword.get(opts, :grid)

    if interval do
      Process.send_after(self(), :tick, interval)
    end

    {:ok,
     %{
       grid: grid,
       interval: interval,
       counter: 0
     }}
  end

  @impl true
  def handle_info(:tick, state) do
    Grid.tick(state.grid, state.counter)
    Process.send_after(self(), :tick, state.interval)

    {:noreply, %{state | counter: state.counter + 1}}
  end

  @impl true
  def terminate(_reason, state) do
    :ets.delete(state.grid)

    :ok
  end
end
