defmodule FallingSand.GridServerTest do
  use ExUnit.Case
  doctest FallingSand.GridServer
  alias FallingSand.Cursors
  alias FallingSand.GridServer
  alias FallingSand.Grid

  test "grid server" do
    grid = Grid.new()
    cursors = Cursors.new()
    {:ok, pid} = GridServer.start_link(tick: nil, grid: grid, cursors: cursors)
    Phoenix.PubSub.subscribe(FallingSand.PubSub, "grid")

    Grid.set(grid, {0, 0}, :sand)
    send(pid, :tick)
    assert_receive {:diffs, messages}

    assert [0, 1, :sand] in messages
    assert [0, 0, :empty] in messages
  end

  # TODO I'd like to write a benchmark for GridServer and set different grid modules
end
