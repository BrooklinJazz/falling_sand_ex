defmodule FallingSand.Grid.WithBounds do
  @behaviour FallingSand.Grid

  @impl true
  def all_cells(ref) do
    :ets.match(ref, {{:"$1", :"$2"}, {:_, :"$3"}})
  end

  @impl true
  def tick(ref) do
    diff =
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

    diff
  end

  @impl true
  def new(opts \\ []) do
    name = Keyword.get(opts, :name)
    min = Keyword.get(opts, :min, 0)
    max = Keyword.get(opts, :max, Application.get_env(:falling_sand, :grid_size))
    table_options = [:public, :set] ++ if name, do: [:named_table], else: []
    grid = :ets.new(name, table_options)
    :ets.insert(grid, {:bounds, {min, max}})

    grid
  end

  @impl true
  @spec get(atom() | :ets.tid(), any()) :: atom()
  def get(ref, {x, y}) do
    case :ets.lookup_element(ref, {y, x}, 2, {false, :empty}) do
      {_, element} -> element
    end
  end

  @impl true
  def set(ref, {x, y}, :empty) do
    :ets.delete(ref, {y, x})
  end

  # Storing elements with the row first for bottom-up logic
  def set(ref, {x, y}, element) do
    if in_bounds?(ref, {x, y}) do
      :ets.insert(ref, {{y, x}, {true, element}})
    end
  end

  defp in_bounds?(ref, {x, y}) do
    {min, max} = :ets.lookup_element(ref, :bounds, 2)
    y >= min and y <= max and x >= min and x <= max
  end
end
