defmodule FallingSand.Grid do
  @type element :: :sand | :stone | :empty
  @type coordinate :: {x :: integer(), y :: integer()}
  @type diff :: [{coordinate(), element()}]
  @type grid :: any()
  @type cell :: {coordinate(), element()}
  @type json_safe_cell :: %{x: integer(), y: integer(), element: element()}
  @callback all_cells(grid()) :: list(json_safe_cell())
  @callback bulk_insert(grid(), []) :: list(cell())
  @callback get(grid(), coordinate()) :: cell()
  @callback new :: grid()
  @callback set(grid(), {integer(), integer()}, element()) :: any()
  @callback tick(grid()) :: diff()

  @spec impl() :: any()
  def impl() do
    Application.get_env(:falling_sand, :grid, FallingSand.Grid.WithActiveTracking)
  end

  def all_cells(grid), do: impl().all_cells(grid)
  def bulk_insert(grid, cells), do: impl().bulk_insert(grid, cells)

  def get(grid, coordinates), do: impl().get(grid, coordinates)

  def new, do: impl().new()

  def set(grid, coordinates, value), do: impl().set(grid, coordinates, value)
  def tick(grid), do: impl().tick(grid)
end
