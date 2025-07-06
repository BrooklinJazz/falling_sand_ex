defmodule FallingSand.GridServer do
  alias FallingSand.Grid
  use GenServer

  @tick_interval Application.compile_env!(:falling_sand, :tick_interval)
  @pubsub_topic "grid"

  def start_link(opts) do
    tick = Keyword.get(opts, :tick, @tick_interval)
    name = Keyword.get(opts, :name)
    grid = Keyword.fetch!(opts, :grid)
    GenServer.start_link(__MODULE__, [tick: tick, grid: grid], name: name)
  end

  def init(opts) do
    tick = Keyword.get(opts, :tick)
    grid = Keyword.get(opts, :grid)

    if tick do
      Process.send_after(self(), :tick, tick)
    end

    {:ok,
     %{
       grid: grid,
       tick: tick
     }}
  end

  def handle_info(:tick, state) do
    start = System.monotonic_time(:microsecond)
    diffs = Grid.tick(state.grid)
    finish = System.monotonic_time(:microsecond)
    elapsed_us = finish - start
    IO.puts("Time to run Grid.tick/1: #{elapsed_us / 1_000} ms")

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

  @impl true
  def terminate(_reason, state) do
    :ets.delete(state.grid)

    :ok
  end
end
