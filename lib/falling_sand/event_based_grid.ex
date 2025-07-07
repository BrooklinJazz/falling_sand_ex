defmodule FallingSand.EventBasedGrid do
  def diffs({pending, diffs}, tick) do
    :ets.lookup_element(diffs, tick, 2)
  end

  def new do
    {:ets.new(:pending_inserts, [:set, :public, {:write_concurrency, true}]),
     :ets.new(:diffs, [:ordered_set, :public, {:read_concurrency, true}])}
  end

  def tick({pending_ref, all_ref, diff_ref}, current_tick \\ 0) do
    # apply all pending

    # set {0, 0}, :sand
    # diffs: [[0, 0, :sand]]
    # :set, {0, 0, :sand}
    cells = :ets.match(pending_ref, {{:"$1", :"$2"}, :"$3"})

    diffs =
      case :ets.last(diff_ref) do
        :"$end_of_table" -> []
        diffs -> diffs
      end

    Enum.map(diffs, fn
      [x, y, element] -> nil
    end)

    :ets.insert(diff_ref, {current_tick, cells})

    # |> Enum.map(fn ->
    #   nil
    # end)
  end

  def set({pending_ref, all_ref, diff_ref}, coord, element) do
    :ets.insert(pending_ref, {coord, element})
    {pending_ref, all_ref, diff_ref}
  end
end
