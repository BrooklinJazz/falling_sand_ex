defmodule FallingSand.GridServerTest do
  use ExUnit.Case
  doctest FallingSand.GridServer
  alias FallingSand.Cursors
  alias FallingSand.GridServer
  alias FallingSand.Grid

  # How can I optimize the tick? Is it possible to call tick
  # How can I optimize the tracking of cursors?
  # Option 1: JS Grid
  # The grid does most of the local math, and takes in diffs from broadcast messages when users set other cells.
  # no global consistency
  # Option 2:
  test "grid server" do
    grid = Grid.new()
    cursors = Cursors.new()
    {:ok, pid} = GridServer.start_link(tick: nil, grid: grid, cursors: cursors)
    Phoenix.PubSub.subscribe(FallingSand.PubSub, "grid")

    GridServer.set(grid, {0, 0}, :sand)
    assert_receive {:diffs, [[0, 0, :sand]]}
    send(pid, :tick)
    assert_receive {:diffs, messages}

    assert [0, 1, :sand] in messages
    assert [0, 0, :empty] in messages
  end
end
