defmodule FallingSandTest do
  use ExUnit.Case
  alias FallingSand.Grid

  test "sand falls straight down and stops at boundary" do
    grid =
      Grid.new([
        [:sand],
        [:empty]
      ])

    assert [
             [:empty],
             [:sand]
           ] = grid = Grid.tick(grid)

    assert [
             [:empty],
             [:sand]
           ] = Grid.tick(grid)
  end

  test "sand falls down-left when right is blocked" do
    grid =
      Grid.new([
        [:empty, :sand],
        [:empty, :sand]
      ])

    assert [
             [:empty, :empty],
             [:sand, :sand]
           ] = Grid.tick(grid)
  end

  test "sand falls down-right when left is blocked" do
    grid =
      Grid.new([
        [:sand, :empty],
        [:sand, :empty]
      ])

    assert [
             [:empty, :empty],
             [:sand, :sand]
           ] = Grid.tick(grid)
  end

  test "sand stays put when fully blocked" do
    grid =
      Grid.new([
        [:empty, :sand, :empty],
        [:sand, :sand, :sand]
      ])

    assert [
             [:empty, :sand, :empty],
             [:sand, :sand, :sand]
           ] = Grid.tick(grid)
  end

  test "multiple sand grains fall in one tick" do
    grid =
      Grid.new([
        [:empty, :sand, :empty],
        [:sand, :empty, :sand],
        [:empty, :empty, :empty]
      ])

    assert [
             [:empty, :empty, :empty],
             [:empty, :sand, :empty],
             [:sand, :empty, :sand]
           ] = Grid.tick(grid)
  end

  test "multiple grains don't collide - prioritize falling down" do
    grid =
      Grid.new([
        [:sand, :sand, :sand],
        [:sand, :empty, :sand]
      ])

    assert [
             [:sand, :empty, :sand],
             [:sand, :sand, :sand]
           ] = Grid.tick(grid)
  end
end
