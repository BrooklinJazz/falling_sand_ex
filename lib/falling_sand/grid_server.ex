defmodule FallingSand.GridServer do
  alias FallingSand.Cursors
  alias FallingSand.Grid
  use GenServer

  @tick_interval 15
  @pubsub_topic "grid"
  @size 100

  def start_link(opts) do
    tick = Keyword.get(opts, :tick, @tick_interval)
    name = Keyword.get(opts, :name)
    cursors = Keyword.get(opts, :cursors, :cursors)
    grid = Keyword.get(opts, :grid) || Grid.new()
    GenServer.start_link(__MODULE__, [tick: tick, grid: grid, cursors: cursors], name: name)
  end

  def set(grid \\ :grid, {x, y} = coord, element) do
    Grid.set(grid, coord, element)
    broadcast_diffs([[x, y, element]])
  end

  @spec init(any()) ::
          {:ok,
           %{
             cursors: %{
               String.t() => %{page_id: String.t(), x: integer(), y: integer(), element: atom()}
             }
           }}
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

  def handle_cast({:mouseup, %{page_id: page_id}}, state) do
    cursors = Map.delete(state.cursors, page_id)
    {:noreply, %{state | cursors: cursors}}
  end

  def handle_info(:tick, state) do
    # Maybe the GenServer shouldn't be responsible for this. These could all be set in between-ticks and that would be fine.
    # Cursors.all_cursors(state.cursors) |> Enum
    # Enum.each(state.cursors, fn {_page_id, %{x: x, y: y, element: element}} ->
    #   Grid.set(state.grid, {{x, y}, element})
    # end)

    diffs = Grid.tick(state.grid)

    broadcast_diffs(Enum.map(diffs, fn {{x, y}, element} -> [x, y, element] end))

    if state.tick do
      Process.send_after(self(), :tick, state.tick)
    end

    {:noreply, state}
  end

  def broadcast_diffs(diffs) do
    Phoenix.PubSub.broadcast(
      FallingSand.PubSub,
      @pubsub_topic,
      # eventually I should optimize tick to return this structure
      {:diffs, diffs}
    )
  end
end
