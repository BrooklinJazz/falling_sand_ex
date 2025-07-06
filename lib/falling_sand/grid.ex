defmodule FallingSand.Grid do
  @type element :: :sand | :stone | :empty
  # @type grid :: any()
  # @type coordinate :: {x :: integer(), y :: integer()}
  # @callback all_cells(grid()) :: list(json_safe_cell())
  # @callback get(grid(), coordinate()) :: cell()
  # @callback new(opts :: list()) :: grid()
  # @callback set(grid(), {integer(), integer()}, element()) :: any()
  # @callback tick(grid()) :: diff()
  @min 0
  @max Application.compile_env!(:falling_sand, :grid_size)

  @spec all_cells(:ets.table()) :: list()
  def all_cells(ref) do
    :ets.match(ref, {{:"$2", :"$1"}, {:_, :"$3"}})
  end

  @spec tick(:ets.table()) :: list()
  def tick(ref \\ __MODULE__) do
    :ets.match(ref, {{:"$1", :"$2"}, {true, :"$3"}})
    |> Enum.flat_map(fn [y, x, element] ->
      cond do
        element == :sand and not :ets.member(ref, {y + 1, x}) ->
          set(ref, {x, y}, :empty)
          set(ref, {x, y + 1}, :sand)
          [[x, y, :empty], [x, y + 1, :sand]]

        element == :sand and not :ets.member(ref, {y + 1, x + 1}) ->
          set(ref, {x, y}, :empty)
          set(ref, {x + 1, y + 1}, :sand)
          [[x, y, :empty], [x + 1, y + 1, :sand]]

        element == :sand and not :ets.member(ref, {y + 1, x - 1}) ->
          set(ref, {x, y}, :empty)
          set(ref, {x - 1, y + 1}, :sand)
          [[x, y, :empty], [x - 1, y + 1, :sand]]

        element == :sand ->
          # only set idle if the elements below it are idle.
          with {_, false} <- :ets.lookup_element(ref, {y + 1, x}, 2),
               {_, false} <- :ets.lookup_element(ref, {y + 1, x}, 2),
               {_, false} <- :ets.lookup_element(ref, {y + 1, x}, 2) do
            :ets.update_element(ref, {y, x}, {2, {false, :sand}})
            []
          else
            _ -> []
          end

        element == :stone ->
          :ets.update_element(ref, {y, x}, {2, {false, :stone}})
          [[x, y, :stone]]

        true ->
          raise "Unhandled element condition"
      end
    end)
  end

  @spec new(Keyword.t()) :: :ets.table()
  def new(opts \\ []) do
    name = Keyword.get(opts, :name)
    table_options = [:public, :set] ++ if name, do: [:named_table], else: []
    :ets.new(name, table_options)
  end

  @spec get(:ets.table(), any()) :: atom()
  def get(ref, {x, y}) do
    case :ets.lookup_element(ref, {y, x}, 2, {false, :empty}) do
      {_, element} -> element
    end
  end

  @spec set(:ets.table(), {integer(), integer()}, element()) :: true
  def set(ref, {x, y}, :empty) do
    :ets.delete(ref, {y, x})
  end

  # Storing elements with the row first for bottom-up logic
  def set(ref, {x, y}, element) do
    if in_bounds?({x, y}) do
      :ets.insert(ref, {{y, x}, {true, element}})
    end
  end

  defp in_bounds?({x, y}) do
    y >= @min and y <= @max and x >= @min and x <= @max
  end
end
