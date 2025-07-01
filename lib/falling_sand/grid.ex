defmodule FallingSand.Grid do
  @table_name :grid
  @default_value :empty
  defguard is_element(element) when element in [:sand, :stone]

  def active_cells(table \\ @table_name) do
    :ets.tab2list(table) |> Enum.map(fn {{x, y}, cell} -> %{x: x, y: y, cell: cell} end)
  end

  def tick(table \\ @table_name) do
    :ets.tab2list(table)
    |> Enum.each(fn {{x, y}, cell} ->
      cond do
        cell == :sand and get(table, {x, y + 1}) == :empty ->
          set(table, {x, y + 1}, :sand)
          set(table, {x, y}, :empty)

        cell == :sand and get(table, {x + 1, y + 1}) == :empty ->
          set(table, {x + 1, y + 1}, :sand)
          set(table, {x, y}, :empty)

        cell == :sand and get(table, {x - 1, y + 1}) == :empty ->
          set(table, {x - 1, y + 1}, :sand)
          set(table, {x, y}, :empty)

        true ->
          nil
      end
    end)
  end

  def new(name \\ @table_name, _width, _height) do
    case :ets.whereis(name) do
      :undefined ->
        :ets.new(name, [:named_table, :public, :set])

      tid when is_reference(tid) ->
        tid
    end
  end

  def get(table \\ @table_name, {x, y} = _coordinate) do
    case :ets.lookup(table, {x, y}) do
      [{{^x, ^y}, value}] ->
        value

      _ ->
        @default_value
    end
  end

  @spec set(atom() | :ets.tid(), {integer(), integer()}, atom()) :: true
  def set(table \\ @table_name, coordinate, element)

  def set(table, {x, y}, element) when is_element(element) do
    :ets.insert(table, {{x, y}, element})
  end

  def set(table, {x, y}, :empty) do
    :ets.delete(table, {x, y})
  end
end
