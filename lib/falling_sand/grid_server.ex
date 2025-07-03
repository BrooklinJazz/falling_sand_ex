defmodule FallingSand.GridServer do
  alias FallingSand.Grid
  use GenServer

  @tick_interval 5
  @pubsub_topic "grid"
  @size 500

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @spec init(any()) ::
          {:ok,
           %{
             cursors: %{
               String.t() => %{page_id: String.t(), x: integer(), y: integer(), element: atom()}
             }
           }}
  def init(_) do
    Process.send_after(self(), :tick, @tick_interval)

    grid = Grid.new()

    for x <- 0..(@size - 1) do
      Grid.set(grid, {x, @size - 1}, :stone)
    end

    for y <- 0..(@size - 1) do
      Grid.set(grid, {0, y}, :stone)
      Grid.set(grid, {@size - 1, y}, :stone)
    end

    {:ok,
     %{
       # I'll need to optimize cursors at some point.
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
  def handle_cast({:mousedown, cursor_info}, state) do
    cursors = Map.put(state.cursors, cursor_info.page_id, cursor_info)
    {:noreply, %{state | cursors: cursors}}
  end

  def handle_cast({:mousemove, cursor_info}, state) do
    cursors = Map.put(state.cursors, cursor_info.page_id, cursor_info)
    {:noreply, %{state | cursors: cursors}}
  end

  def handle_cast({:mouseup, %{page_id: page_id}}, state) do
    cursors = Map.delete(state.cursors, page_id)
    {:noreply, %{state | cursors: cursors}}
  end

  def handle_info(:tick, state) do
    # I can probably make a batch update
    inserts =
      Enum.flat_map(state.cursors, fn {page_id, %{x: x, y: y, element: element}} ->
        for xr <- (x - 10)..(x + 10), yr <- (y - 10)..(y + 10) do
          {{xr, yr}, element}
        end
      end)

    Grid.bulk_insert(state.grid, inserts)

    diffs = Grid.tick(state.grid)

    Phoenix.PubSub.broadcast(
      FallingSand.PubSub,
      @pubsub_topic,
      {:diffs, Enum.map(diffs, fn {{x, y}, element} -> %{y: y, x: x, element: element} end)}
    )

    Process.send_after(self(), :tick, @tick_interval)
    {:noreply, state}
  end
end
