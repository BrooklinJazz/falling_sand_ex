defmodule FallingSand.GridServer do
  alias FallingSand.Grid
  use GenServer

  @tick_interval Application.compile_env!(:falling_sand, :tick_interval)
  @pubsub_topic "grid"

  def start_link(opts) do
    tick = Keyword.get(opts, :tick, @tick_interval)
    name = Keyword.get(opts, :name)
    cursors = Keyword.get(opts, :cursors, :cursors)
    grid = Keyword.get(opts, :grid) || Grid.new()
    GenServer.start_link(__MODULE__, [tick: tick, grid: grid, cursors: cursors], name: name)
  end

  def init(opts) do
    tick = Keyword.get(opts, :tick)
    grid = Keyword.get(opts, :grid)
    cursors = Keyword.get(opts, :cursors)

    if tick do
      Process.send_after(self(), :tick, tick)
    end

    {:ok,
     %{
       cursors: cursors,
       grid: grid,
       tick: tick
     }}
  end

  def all_cells() do
    GenServer.call(__MODULE__, :all_cells)
  end

  def handle_call(:all_cells, _from, state) do
    {:reply, Grid.all_cells(state.grid), state}
  end

  def handle_info(:tick, state) do
    diffs = Grid.tick(state.grid)

    case diffs do
      [] -> nil
      diffs -> broadcast_diffs(diffs)
    end

    if state.tick do
      Process.send_after(self(), :tick, state.tick)
    end

    {:noreply, state}
  end

  def broadcast_diffs(diffs) do
    Phoenix.PubSub.broadcast(
      FallingSand.PubSub,
      @pubsub_topic,
      {:diffs, diffs}
    )
  end
end
