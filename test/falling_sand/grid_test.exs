defmodule FallingSand.GridTest do
  use ExUnit.Case
  doctest FallingSand.Grid
  alias FallingSand.Grid.ETSDiffs, as: Grid
  alias FallingSand.Grid.ETSDiffs
  alias FallingSand.Grid.ETS
  alias FallingSand.Grid.Maps

  test "all_cells/1" do
    grid = Grid.new()
    grid = Grid.set(grid, {0, 0}, :sand)
    assert [%{y: 0, x: 0, element: :sand}] = Grid.all_cells(grid)
  end

  test "get/2" do
    grid = Grid.new()

    assert Grid.get(grid, {0, 0}) == :empty
  end

  test "set/3" do
    grid = Grid.new()
    grid = Grid.set(grid, {0, 0}, :sand)
    assert Grid.get(grid, {0, 0}) == :sand
  end

  test "tick/1 _ sand falls _ returns diff with sand" do
    grid = Grid.new()
    Grid.set(grid, {0, 0}, :sand)
    diff = Grid.tick(grid)
    assert {{0, 0}, :empty} in diff
    assert {{0, 1}, :sand} in diff
    assert Grid.get(grid, {0, 0}) == :empty
    assert Grid.get(grid, {0, 1}) == :sand
  end

  test "tick/1 sand stops when blocked" do
    grid = Grid.new()
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

  @tag :skip
  test "tick/1 sand stops at edges? I'm not sure if this will be needed if I do an infinite sim..."

  @tag :benchmark
  @tag timeout: :infinity
  test "benchmark tick cycle" do
    output =
      Benchee.run(
        %{
          "ETS" => {
            fn {coordinates, frames, grid} ->
              Enum.each(coordinates, fn coord ->
                ETS.set(grid, coord, :sand)
              end)

              # Enum.each(1..frames, fn _ ->
              #   ETS.tick(grid)
              #   ETS.all_cells(grid)
              # end)
            end,
            before_scenario: fn {coordinates, frames} ->
              grid = ETS.new()
              {coordinates, frames, grid}
            end
          },
          "ETS with diffs" => {
            fn {coordinates, frames, grid} ->
              Enum.each(coordinates, fn coord ->
                ETSDiffs.set(grid, coord, :sand)
              end)

              # Enum.each(1..frames, fn _ ->
              #   ETSDiffs.tick(grid)
              # end)
            end,
            before_scenario: fn {coordinates, frames} ->
              grid = ETSDiffs.new()
              {coordinates, frames, grid}
            end
          }
          # "Maps" => fn {coordinates, frames} ->
          #   grid = Maps.new()

          #   grid =
          #     Enum.reduce(coordinates, grid, fn coord, new_grid ->
          #       Maps.set(new_grid, coord, :sand)
          #     end)

          #   grid =
          #     Enum.reduce(1..frames, grid, fn _, new_grid ->
          #       Maps.tick(grid)
          #       Maps.all_cells(new_grid)
          #       new_grid
          #     end)
          # end
        },
        inputs: %{
          # "1000 cells at 15 fps" => {generate_coords(1000), 15},
          # "1000 cells at 60 fps" => {generate_coords(1000), 60},
          # "5000 cells at 15 fps" => {generate_coords(1000), 15},
          "10000 cells at 15 fps" => {generate_coords(10000), 15}
          # "17500 cells at 15 fps" => {generate_coords(17500), 15},
          # "25000 cells at 15 fps" => {generate_coords(25000), 15},
          # "50000 cells at 15 fps" => {generate_coords(50000), 15}
          # "75000 cells at 15 fps" => {generate_coords(75000), 15},
          # "100000 cells at 15 fps" => {generate_coords(100_000), 15}
        }
      )

    # one_second = 1_000_000_000

    # original = Enum.at(output.scenarios, 0)
    # map_impl = Enum.at(output.scenarios, 1)

    # assert map_impl.run_time_data.statistics.average <= original.run_time_data.statistics.average
  end

  defp generate_coords(size) do
    for n <- 1..size do
      {Enum.random(1..(size * 1000)), Enum.random(1..(size * 1000))}
    end
  end
end
