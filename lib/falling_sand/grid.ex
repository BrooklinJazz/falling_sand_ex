defmodule FallingSand.Grid do
  @type element :: :sand | :stone | :empty
  @type cell :: %{x: integer(), y: integer(), element: element()}
  @type coord :: {x :: integer(), y :: integer()}
  @callback all_cells(any()) :: list(cell())
  @callback get(any(), coord()) :: cell()
  @callback new :: any()
  @callback set(any(), {integer(), integer()}, value :: element()) :: any()
  @callback tick(any()) :: any()

  @spec impl() :: any()
  def impl() do
    Application.get_env(:falling_sand, :grid, FallingSand.Grid.Optimized)
  end

  def all_cells(grid), do: impl().all_cells(grid)
  def bulk_insert(grid, cells), do: impl().bulk_insert(grid, cells)

  def get(grid, coordinates), do: impl().get(grid, coordinates)

  def new, do: impl().new()

  def set(grid, coordinates, value), do: impl().set(grid, coordinates, value)
  def tick(grid), do: impl().tick(grid)

  defmodule ETS do
    @behaviour FallingSand.Grid
    @type element() :: :sand | :stone | :empty
    @type cell() :: {element(), boolean()}
    @type coord() :: {integer(), integer()}

    def all_cells(table) do
      :ets.tab2list(table)
      |> Enum.map(fn {{x, y}, {element, _}} -> %{y: y, x: x, element: element} end)
    end

    def tick(table) do
      :ets.select(table, [{{:"$1", {:_, true}}, [], [:"$_"]}])
      |> Enum.each(fn {{x, y} = coord, {element, _is_active}} ->
        {down, down_active} = get_cell(table, {x, y + 1})
        {down_right, down_right_active} = get_cell(table, {x + 1, y + 1})
        {down_left, down_left_active} = get_cell(table, {x - 1, y + 1})

        cond do
          element == :sand and down == :empty ->
            set(table, {x, y + 1}, :sand)
            delete(table, coord)

          element == :sand and down_right == :empty ->
            set(table, {x + 1, y + 1}, :sand)
            delete(table, coord)

          element == :sand and down_left == :empty ->
            set(table, {x - 1, y + 1}, :sand)
            delete(table, coord)

          not down_left_active and not down_active and not down_right_active ->
            set_inactive(table, coord, :sand)

          true ->
            nil
        end
      end)

      table
    end

    def new() do
      :ets.new(:grid, [:public, :set])
    end

    @spec get(atom() | :ets.tid(), coord()) :: element()
    def get(table, coord) do
      case :ets.lookup(table, coord) do
        [{_coord, {element, _active}}] ->
          element

        _ ->
          :empty
      end
    end

    @spec get_cell(atom() | :ets.tid(), coord()) :: cell()
    def get_cell(table, coord) do
      case :ets.lookup(table, coord) do
        [{_coord, cell}] ->
          cell

        _ ->
          {:empty, false}
      end
    end

    def delete(table, {x, y}) do
      :ets.delete(table, {x, y})
    end

    def set(table, coord, :stone) do
      :ets.insert(table, {coord, {:stone, false}})
    end

    def set(table, coord, :empty) do
      delete(table, coord)
    end

    def set(table, {x, y}, element) do
      :ets.insert(table, {{x, y}, {element, true}})
    end

    def set_inactive(table, coord, element) do
      :ets.insert(table, {coord, {element, false}})
    end
  end

  defmodule Optimized do
    @behaviour FallingSand.Grid
    @type element() :: :sand | :stone | :empty
    @type cell() :: {element(), boolean()}
    @type grid() :: {all :: :ets.tid(), active :: :ets.tid()}
    @type coord() :: {integer(), integer()}

    def all_cells({all_ref, active_ref}) do
      :ets.tab2list(all_ref)
      |> Enum.map(fn {{x, y}, element} -> %{y: y, x: x, element: element} end)
    end

    def tick({all_ref, active_ref}) do
      diffs =
        :ets.tab2list(active_ref)
        |> Enum.reduce([], fn {{x, y} = coord, _}, acc ->
          element = :ets.lookup_element(all_ref, coord, 2)
          down = {x, y + 1}
          down_right = {x + 1, y + 1}
          down_left = {x - 1, y + 1}

          cond do
            element == :sand and not :ets.member(all_ref, down) ->
              :ets.delete(all_ref, coord)
              [{down, :sand} | [{coord, :empty} | acc]]

            element == :sand and not :ets.member(all_ref, down_right) ->
              :ets.delete(all_ref, coord)
              [{down_right, :sand} | [{coord, :empty} | acc]]

            element == :sand and not :ets.member(all_ref, down_left) ->
              :ets.delete(all_ref, coord)
              [{down_left, :sand} | [{coord, :empty} | acc]]

            :ets.member(active_ref, down) or :ets.member(active_ref, down_right) or
                :ets.member(active_ref, down_left) ->
              # preserves cell as active
              [{coord, :sand} | acc]

            true ->
              acc
          end
        end)

      inserts = Enum.filter(diffs, fn {_coord, element} -> element != :empty end)

      :ets.insert(all_ref, inserts)
      :ets.delete_all_objects(active_ref)
      :ets.insert(active_ref, Enum.map(inserts, fn {coord, _element} -> {coord, true} end))
      diffs
    end

    def new() do
      {:ets.new(:grid, [:public, :set]), :ets.new(:grid, [:public, :set])}
    end

    def get({all_cells, _}, coord) do
      case :ets.lookup(all_cells, coord) do
        [{_coord, element}] ->
          element

        _ ->
          :empty
      end
    end

    @spec bulk_insert(grid(), [{{integer(), integer()}, element()}]) :: true
    # should never be given :empty
    def bulk_insert({all_ref, active_ref}, inserts) do
      :ets.insert(all_ref, inserts)
      :ets.insert(active_ref, inserts)
    end

    def set({all_ref, active_ref}, coord, :empty) do
      :ets.delete(all_ref, coord)
      :ets.delete(active_ref, coord)
    end

    def set({all_ref, _}, coord, :stone) do
      :ets.insert(all_ref, {coord, :stone})
    end

    def set({all_ref, active_ref}, coord, element) do
      :ets.insert(all_ref, {coord, element})
      :ets.insert(active_ref, {coord, true})
    end
  end
end
