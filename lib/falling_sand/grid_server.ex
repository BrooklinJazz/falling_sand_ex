defmodule FallingSand.GridServer do
  alias FallingSand.Grid
  use GenServer

  @tick_interval 15
  @pubsub_topic "grid"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @spec init(any()) :: {:ok, %{cursors: %{page_id: String.t(), x: integer(), y: integer()}}}
  def init(_) do
    Process.send_after(self(), :tick, @tick_interval)

    grid = Grid.new()

    for x <- 0..(100 - 1) do
      Grid.set(grid, {x, 100 - 1}, :stone)
    end

    for y <- 0..(100 - 1) do
      Grid.set(grid, {0, y}, :stone)
      Grid.set(grid, {100 - 1, y}, :stone)
    end

    {:ok,
     %{
       # eventually cursors will need to be
       cursors: %{},
       grid: grid
     }}
  end

  def all_cells() do
    GenServer.call(__MODULE__, :all_cells)
  end

  def handle_call(:all_cells, _from, state) do
    {:reply, Grid.all_cells(state.grid), state}
  end

  # I'm concerned about cursors getting stuck on the page if the user exits.
  # Maybe use presence or something to monitor joins, as well as a timer?
  def handle_cast({:mousedown, %{y: y, x: x, page_id: page_id}}, state) do
    cursors = Map.update(state.cursors, page_id, {x, y}, fn _ -> {x, y} end)
    {:noreply, %{state | cursors: cursors}}
  end

  def handle_cast({:mousemove, %{y: y, x: x, page_id: page_id}}, state) do
    cursors = Map.update(state.cursors, page_id, {x, y}, fn _ -> {x, y} end)
    {:noreply, %{state | cursors: cursors}}
  end

  def handle_cast({:mouseup, %{page_id: page_id}}, state) do
    cursors = Map.delete(state.cursors, page_id)
    {:noreply, %{state | cursors: cursors}}
  end

  def handle_info(:tick, state) do
    # I can probably make a batch update
    Enum.each(state.cursors, fn {_page_id, {x, y}} ->
      Grid.set(state.grid, {x, y}, :sand)
    end)

    Grid.tick(state.grid)

    Phoenix.PubSub.broadcast(
      FallingSand.PubSub,
      @pubsub_topic,
      {:diffs, Grid.all_cells(state.grid)}
    )

    Process.send_after(self(), :tick, @tick_interval)
    {:noreply, state}
  end
end
