defmodule FallingSand.Grid do
  @type element :: :sand | :stone | :empty
  @type coordinate :: {x :: integer(), y :: integer()}
  @type diff :: [{coordinate(), element()}]
  @type grid :: any()
  @type cell :: {coordinate(), element()}
  @type json_safe_cell :: %{x: integer(), y: integer(), element: element()}
  @callback all_cells(grid()) :: list(json_safe_cell())
  @callback get(grid(), coordinate()) :: cell()
  @callback new(name :: atom()) :: grid()
  @callback set(grid(), {integer(), integer()}, element()) :: any()
  @callback tick(grid()) :: diff()

  @spec impl() :: any()
  def impl() do
    # I do this to make swapping to new versions easier, and it lets me benchmark and test new optimized versins against the old verson.
    FallingSand.Grid.WithBounds
  end

  def all_cells(grid), do: impl().all_cells(grid)

  def get(grid, coordinates), do: impl().get(grid, coordinates)

  @spec new(list()) :: any()
  def new(opts \\ []), do: impl().new(opts)

  def set(grid, coordinates, value), do: impl().set(grid, coordinates, value)
  def tick(grid), do: impl().tick(grid)
end
