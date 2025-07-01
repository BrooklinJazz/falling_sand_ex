defmodule FallingSand.GridTest do
  use ExUnit.Case
  doctest FallingSand.Grid
  alias FallingSand.Grid

  test "new/1" do
    # check to make sure new/1 is idempotent
    assert Grid.new(:grid_name) == :grid_name
    assert is_reference(Grid.new(:grid_name))
  end

  test "get/2" do
    grid = Grid.new(:get_test)

    assert Grid.get(grid, {0, 0}) == :empty
  end

  test "set/3" do
    grid = Grid.new(:set_test)
    Grid.set(grid, {0, 0}, :sand)
    assert Grid.get(grid, {0, 0}) == :sand
  end

  test "tick/1 sand falls" do
    grid = Grid.new(:tick_test)
    Grid.set(grid, {0, 0}, :sand)
    Grid.tick(grid)
    assert Grid.get(grid, {0, 0}) == :empty
    assert Grid.get(grid, {0, 1}) == :sand
  end

  test "tick/1 sand stops when blocked" do
    grid = Grid.new(:tick_test)
    Grid.set(grid, {1, 0}, :sand)
    Grid.set(grid, {0, 1}, :stone)
    Grid.set(grid, {1, 1}, :stone)
    Grid.set(grid, {2, 1}, :stone)
    Grid.tick(grid)

    assert Grid.get(grid, {1, 0}) == :sand
    assert Grid.get(grid, {0, 1}) == :stone
    assert Grid.get(grid, {1, 1}) == :stone
    assert Grid.get(grid, {2, 1}) == :stone
  end

  test "tick/1 sand stops at edges? I'm not sure if this will be needed if I do an infinite sim..."
end
