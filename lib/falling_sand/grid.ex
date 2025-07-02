defmodule FallingSand.Grid do
  @type element :: :sand | :stone | :empty
  @type cell :: %{x: integer(), y: integer(), element: element()}
  @type coord :: {x :: integer(), y :: integer()}
  @callback active_cells(any()) :: list(cell())
  @callback all_cells(any()) :: list(cell())
  @callback get(any(), coord()) :: cell()
  @callback new :: any()
  @callback set(any(), {integer(), integer()}, value :: element()) :: any()
  @callback tick(any()) :: any()

  defdelegate active_cells(grid),
    to: Application.compile_env(:falling_sand, :grid, FallingSand.Grid.ETS)

  defdelegate all_cells(grid),
    to: Application.compile_env(:falling_sand, :grid, FallingSand.Grid.ETS)

  defdelegate get(grid, coordinates),
    to: Application.compile_env(:falling_sand, :grid, FallingSand.Grid.ETS)

  defdelegate new, to: Application.compile_env(:falling_sand, :grid, FallingSand.Grid.ETS)

  defdelegate set(grid, coordinates, value),
    to: Application.compile_env(:falling_sand, :grid, FallingSand.Grid.ETS)

  defdelegate tick(grid), to: Application.compile_env(:falling_sand, :grid, FallingSand.Grid.ETS)

  defmodule ETS do
    @behaviour FallingSand.Grid
    @default_value :empty
    defguard is_element(element) when element in [:sand, :stone]

    def active_cells(table) do
      raise "Not yet implemented"
    end

    def all_cells(table) do
      :ets.tab2list(table)
      |> Enum.map(fn {{x, y}, element} -> %{x: x, y: y, element: element} end)
    end

    def tick(table) do
      :ets.tab2list(table)
      |> Enum.each(fn {{x, y}, element} ->
        cond do
          element == :sand and get(table, {x, y + 1}) == :empty ->
            set(table, {x, y + 1}, :sand)
            set(table, {x, y}, :empty)

          element == :sand and get(table, {x + 1, y + 1}) == :empty ->
            set(table, {x + 1, y + 1}, :sand)
            set(table, {x, y}, :empty)

          element == :sand and get(table, {x - 1, y + 1}) == :empty ->
            set(table, {x - 1, y + 1}, :sand)
            set(table, {x, y}, :empty)

          true ->
            nil
        end
      end)

      table
    end

    def new() do
      :ets.new(:grid, [:public, :set])
    end

    def get(table, {x, y} = _coordinate) do
      case :ets.lookup(table, {x, y}) do
        [{{^x, ^y}, value}] ->
          value

        _ ->
          @default_value
      end
    end

    @spec set(atom() | :ets.tid(), {integer(), integer()}, atom()) :: true
    def set(table, coordinate, element)

    def set(table, {x, y}, element) when is_element(element) do
      :ets.insert(table, {{x, y}, element})
      table
    end

    def set(table, {x, y}, :empty) do
      :ets.delete(table, {x, y})
      table
    end
  end

  defmodule Maps do
    @behaviour FallingSand.Grid

    @type cell :: FallingSand.Grid.cell()
    @type coord :: FallingSand.Grid.coord()
    @type element :: FallingSand.Grid.element()
    @type grid() :: {active_cells :: MapSet.t(), all_cells :: map()}

    @default_value :empty
    defguard is_element(element) when element in [:sand, :stone]

    @spec active_cells(grid()) :: FallingSand.Grid.cell()
    def active_cells({map_set, map}) do
      raise "Not yet implemented"
    end

    @spec all_cells(grid()) :: list(FallingSand.Grid.cell())
    def all_cells({_, map}) do
      Enum.map(map, fn {x, y} = coords -> %{y: y, x: x, element: Map.get(map, coords)} end)
    end

    @spec tick(grid()) :: grid()
    def tick({map_set, _map} = table) do
      Enum.reduce(map_set, table, fn {x, y} = coord, new_table ->
        element = get(new_table, coord)

        cond do
          element == :sand and get(new_table, {x, y + 1}) == :empty ->
            new_table
            |> set({x, y + 1}, :sand)
            |> set({x, y}, :empty)

          element == :sand and get(new_table, {x + 1, y + 1}) == :empty ->
            new_table
            |> set({x + 1, y + 1}, :sand)
            |> set({x, y}, :empty)

          element == :sand and get(new_table, {x - 1, y + 1}) == :empty ->
            new_table
            |> set({x - 1, y + 1}, :sand)
            |> set({x, y}, :empty)

          true ->
            new_table
        end
      end)
    end

    @spec new :: grid()
    def new() do
      {MapSet.new(), %{}}
    end

    @spec new :: grid()
    def get({map_set, map}, coord) do
      if MapSet.member?(map_set, coord) do
        Map.get(map, coord)
      else
        @default_value
      end
    end

    @spec set(grid(), coord(), element()) :: grid()
    def set({map_set, map}, coord, element) when is_element(element) do
      {MapSet.put(map_set, coord), Map.put(map, coord, element)}
    end

    def set({map_set, map}, coord, :empty) do
      {MapSet.delete(map_set, coord), Map.delete(map, coord)}
    end
  end
end
