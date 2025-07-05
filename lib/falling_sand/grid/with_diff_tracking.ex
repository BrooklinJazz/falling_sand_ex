defmodule FallingSand.Grid.WithDiffTracking do
  @behaviour FallingSand.Grid

  @impl true
  def all_cells(name) do
    :ets.tab2list(all_ref(name))
    |> Enum.map(fn {{x, y}, element} -> [x, y, element] end)
  end

  @impl true
  def tick(name) do
    all_ref = all_ref(name)
    active_ref = active_ref(name)
    diff_ref = diff_ref(name)
    {all_ref, active_ref, diff_ref}
    # These being unsorted might cause problems
    # I'm considering storing as {y, x} in an ordered set so they will be top-down.
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

        element == :stone ->
          # used by GridServer to broadcast the diff
          :ets.insert(diff_ref, {coord, :stone})
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
  def new(name \\ nil) do
    name = name || UUID.uuid1()
    opts = [:public, :set, :named_table]
    :ets.new(all_ref(name), opts)
    :ets.new(active_ref(name), opts)
    :ets.new(diff_ref(name), opts)

    name
  end

  @impl true
  def get(name, coord) do
    case :ets.lookup(all_ref(name), coord) do
      [{_coord, element}] ->
        element

      _ ->
        :empty
    end
  end

  @impl true
  def set(name, coord, :empty) do
    :ets.delete(all_ref(name), coord)
    :ets.delete(active_ref(name), coord)
  end

  def set(name, coord, element) do
    :ets.insert(all_ref(name), {coord, element})
    :ets.insert(active_ref(name), {coord, true})
  end

  defp reserved?(diff_ref, coord) do
    case :ets.lookup(diff_ref, coord) do
      [{_, :empty}] -> false
      [{_, _element}] -> true
      _ -> false
    end
  end

  defp active_ref(name), do: String.to_atom("#{name}_active")
  defp all_ref(name), do: String.to_atom("#{name}_all")
  defp diff_ref(name), do: String.to_atom("#{name}_diff")
end
