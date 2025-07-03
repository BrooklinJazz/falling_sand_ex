defmodule FallingSand.Grid.WithDiffTracking do
  @behaviour FallingSand.Grid

  @impl true
  def all_cells({all_ref, _, _}) do
    :ets.tab2list(all_ref)
    |> Enum.map(fn {{x, y}, element} -> %{y: y, x: x, element: element} end)
  end

  @impl true
  def tick({all_ref, active_ref, diff_ref}) do
    # These being unsorted might be causing me problems
    :ets.tab2list(active_ref)
    |> Enum.each(fn {{x, y} = coord, true} ->
      element = :ets.lookup_element(all_ref, coord, 2)
      down = {x, y + 1}
      down_right = {x + 1, y + 1}
      down_left = {x - 1, y + 1}

      cond do
        element == :sand and not :ets.member(all_ref, down) and not reserved?(diff_ref, down) ->
          :ets.delete(all_ref, coord)
          :ets.delete(active_ref, coord)
          :ets.insert(all_ref, {down, :sand})
          :ets.insert(active_ref, {down, true})
          :ets.insert(diff_ref, [{down, :sand}, {coord, :empty}])

        element == :sand and not :ets.member(all_ref, down_right) and
            not reserved?(diff_ref, down_right) ->
          :ets.delete(all_ref, coord)
          :ets.delete(active_ref, coord)
          :ets.insert(all_ref, {down_right, :sand})
          :ets.insert(active_ref, {down_right, true})
          :ets.insert(diff_ref, [{down_right, :sand}, {coord, :empty}])

        element == :sand and not :ets.member(all_ref, down_left) and
          not :ets.member(diff_ref, down_left) and not reserved?(diff_ref, down_left) ->
          :ets.delete(all_ref, coord)
          :ets.delete(active_ref, coord)
          :ets.insert(all_ref, {down_left, :sand})
          :ets.insert(active_ref, {down_left, true})
          :ets.insert(diff_ref, [{down_left, :sand}, {coord, :empty}])

        # elements are all filled but not active
        element == :sand and not :ets.member(active_ref, down) and
          not :ets.member(active_ref, down_left) and not :ets.member(active_ref, down_right) ->
          :ets.delete(active_ref, coord)

        true ->
          nil
      end
    end)

    diffs = :ets.tab2list(diff_ref)
    :ets.delete_all_objects(diff_ref)
    diffs
  end

  @impl true
  def new() do
    {
      :ets.new(:grid, [:public, :set]),
      :ets.new(:grid, [:public, :set]),
      :ets.new(:grid, [:public, :set])
    }
  end

  @impl true
  def get({all_cells, _, _}, coord) do
    case :ets.lookup(all_cells, coord) do
      [{_coord, element}] ->
        element

      _ ->
        :empty
    end
  end

  def get(table, coord) do
    case :ets.lookup(table, coord) do
      [{_coord, element}] ->
        element

      _ ->
        :empty
    end
  end

  @impl true
  def set({all_ref, active_ref, _}, coord, :empty) do
    :ets.delete(all_ref, coord)
    :ets.delete(active_ref, coord)
  end

  def set({all_ref, _, _}, coord, :stone) do
    :ets.insert(all_ref, {coord, :stone})
  end

  def set({all_ref, active_ref, _}, coord, element) do
    :ets.insert(all_ref, {coord, element})
    :ets.insert(active_ref, {coord, true})
  end

  defp reserved?(diff_ref, coord) do
    case :ets.lookup(diff_ref, coord) do
      [{_, :empty}] -> false
      [{_, _element}] -> true
      _ -> false
    end
  end
end
