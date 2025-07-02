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

  # Note: I'm worried because ETS won't guaranteed order of coords we'll have issues.
  defmodule ETSDiffs do
    @behaviour FallingSand.Grid
    @default_value :empty

    defguard is_element(element) when element in [:sand, :stone]

    def new(name \\ nil) do
      name = name || String.to_atom(UUID.uuid1())

      :ets.new(all_cells_table(name), [
        :named_table,
        :public,
        :set,
        {:read_concurrency, true}
      ])

      :ets.new(active_cells_table(name), [:named_table, :public, :set])
      :ets.new(diff_cells_since_last_tick_table(name), [:named_table, :public, :set])
      name
    end

    def all_cells(name) do
      :ets.tab2list(all_cells_table(name))
      |> Enum.map(fn {{x, y}, element} -> %{y: y, x: x, element: element} end)
    end

    def tick(name) do
      :ets.tab2list(active_cells_table(name))
      |> Enum.each(fn {{x, y} = coord, element} ->
        down_left = {x - 1, y + 1}
        down_right = {x + 1, y + 1}
        down = {x, y + 1}

        cond do
          element == :sand and get(name, down) == :empty ->
            set(name, down, :sand)
            set(name, coord, :empty)

          element == :sand and get(name, down_right) == :empty ->
            set(name, down_right, :sand)
            set(name, coord, :empty)

          element == :sand and get(name, down_left) == :empty ->
            set(name, down_left, :sand)
            set(name, coord, :empty)

          # all cells below are filled and inactive
          # this might need to change if some cells allow cells through them like water?
          not :ets.member(active_cells_table(name), down_left) and
            not :ets.member(active_cells_table(name), down) and
              not :ets.member(active_cells_table(name), down_right) ->
            :ets.delete(active_cells_table(name), coord)

          true ->
            nil
        end
      end)

      diff = :ets.tab2list(diff_cells_since_last_tick_table(name))
      :ets.delete_all_objects(diff_cells_since_last_tick_table(name))
      diff
    end

    def get(name \\ __MODULE__, coord) do
      case :ets.lookup(all_cells_table(name), coord) do
        [{_, value}] ->
          value

        _ ->
          @default_value
      end
    end

    # I might want to do a single source of truth in the all_cells_table
    def set(name \\ __MODULE__, coord, element)

    def set(name, coord, :empty) do
      with true <- :ets.delete(all_cells_table(name), coord),
           true <- :ets.delete(active_cells_table(name), coord),
           true <- :ets.insert(diff_cells_since_last_tick_table(name), {coord, :empty}) do
        name
      end
    end

    def set(name, coord, element) do
      with true <- :ets.insert(all_cells_table(name), {coord, element}),
           true <- :ets.insert(active_cells_table(name), {coord, element}),
           true <- :ets.insert(diff_cells_since_last_tick_table(name), {coord, element}) do
        name
      end
    end

    defp all_cells_table(name) do
      String.to_atom("all_cells_#{name}")
    end

    defp active_cells_table(name) do
      String.to_atom("active_cells_#{name}")
    end

    defp diff_cells_since_last_tick_table(name) do
      String.to_atom("diff_cells_#{name}")
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
