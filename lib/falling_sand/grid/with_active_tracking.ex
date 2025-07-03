defmodule FallingSand.Grid.WithActiveTracking do
  @behaviour FallingSand.Grid

  @impl true
  def all_cells({all_ref, _active_ref}) do
    :ets.tab2list(all_ref)
    |> Enum.map(fn {{x, y}, element} -> %{y: y, x: x, element: element} end)
  end

  @impl true
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

  @impl true
  def new() do
    {:ets.new(:grid, [:public, :set]), :ets.new(:grid, [:public, :set])}
  end

  @impl true
  def get({all_cells, _}, coord) do
    case :ets.lookup(all_cells, coord) do
      [{_coord, element}] ->
        element

      _ ->
        :empty
    end
  end

  @impl true
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
