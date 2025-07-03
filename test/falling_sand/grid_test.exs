defmodule FallingSand.GridTest do
  use ExUnit.Case
  alias FallingSand.Grid.ETS
  alias FallingSand.Grid.Optimized
  alias FallingSand.Grid

  test "all_cells/1" do
    grid = Grid.new()
    Grid.set(grid, {0, 0}, :sand)
    assert [%{y: 0, x: 0, element: :sand}] = Grid.all_cells(grid)
  end

  test "get/2" do
    grid = Grid.new()

    assert Grid.get(grid, {0, 0}) == :empty
  end

  test "set/3" do
    grid = Grid.new()
    Grid.set(grid, {0, 0}, :sand)
    assert Grid.get(grid, {0, 0}) == :sand
  end

  test "bulk_insert/2" do
    grid = Grid.new()
    Grid.bulk_insert(grid, [{{0, 0}, :sand}, {{0, 1}, :sand}])
    assert Grid.get(grid, {0, 0}) == :sand
    assert Grid.get(grid, {0, 1}) == :sand
  end

  test "tick/1 _ sand falls" do
    grid = Grid.new()
    Grid.set(grid, {0, 0}, :sand)
    Grid.tick(grid)
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

  test "tick/1 sand falls in a line" do
    grid = Grid.new()
    Grid.set(grid, {0, 0}, :sand)
    Grid.set(grid, {0, 1}, :sand)
    Grid.tick(grid)

    assert Grid.get(grid, {0, 0}) == :empty
    assert Grid.get(grid, {0, 1}) == :sand
    assert Grid.get(grid, {0, 2}) == :sand
  end

  test "tick/1 many grains" do
    {all_cells, active_cells} = grid = Optimized.new()
    coordinates = Enum.map(1..50000, fn n -> {{n, 0}, :sand} end)

    Enum.each(coordinates, fn {coord, element} ->
      Optimized.set(grid, coord, element)
    end)

    coord = {45203, 0}

    Enum.each(1..60, fn _ ->
      Optimized.tick(grid)
    end)
  end

  test "tick/1 returns the diffs" do
    grid = Grid.new()
    Grid.set(grid, {0, 0}, :sand)
    diffs = Grid.tick(grid)
    assert {{0, 0}, :empty} in diffs
    assert {{0, 1}, :sand} in diffs
    diffs = Grid.tick(grid)
    assert {{0, 1}, :empty} in diffs
    assert {{0, 2}, :sand} in diffs
  end

  @tag :skip
  test "tick/1 sand stops at edges? I'm not sure if this will be needed if I do an infinite sim..."

  @tag :benchmark
  @tag timeout: :infinity
  test "benchmark all fns" do
    Benchee.run(
      %{
        "Grid.get/2" => {
          fn {grid, coordinates} ->
            Enum.each(coordinates, fn {coord, _element} ->
              Grid.get(grid, coord)
            end)
          end,
          before_scenario: fn coordinates ->
            {Grid.new(), coordinates}
          end
        },
        "Grid.set/3" => {
          fn {grid, coordinates} ->
            Enum.each(coordinates, fn {coord, element} ->
              Grid.set(grid, coord, element)
            end)
          end,
          before_scenario: fn coordinates ->
            {Grid.new(), coordinates}
          end
        }
      },
      inputs: %{
        "50K Sand Particles" => Enum.map(1..50000, fn n -> {{n, 0}, :sand} end),
        "50K Same Particle" => Enum.map(1..50000, fn _ -> {{0, 0}, :sand} end),
        "50K Empty Particle" => Enum.map(1..50000, fn n -> {{n, 0}, :empty} end)
      }
    )
  end

  @tag :benchmark
  @tag timeout: :infinity
  test "benchmark tick cycle" do
    Benchee.run(
      %{
        "ETS.tick/1" => {
          fn grid ->
            Enum.each(1..60, fn _ ->
              ETS.tick(grid)
            end)
          end,
          before_scenario: fn coordinates ->
            grid = ETS.new()

            Enum.each(coordinates, fn {coord, element} ->
              ETS.set(grid, coord, element)
            end)

            grid
          end
        },
        "Optimized.tick/1" => {
          fn grid ->
            Enum.each(1..60, fn _ ->
              Optimized.tick(grid)
            end)
          end,
          before_scenario: fn coordinates ->
            grid = Optimized.new()

            Enum.each(coordinates, fn {coord, element} ->
              Optimized.set(grid, coord, element)
            end)

            grid
          end
        }
      },
      inputs: %{
        "50K Sand Particles Falling" => Enum.map(1..50000, fn n -> {{n, 0}, :sand} end),
        "50K Sand Particles Fall then Idle" =>
          Enum.map(1..50000, fn n -> {{n, 0}, :sand} end) ++
            Enum.map(0..50001, fn n -> {{n, 2}, :stone} end)
      }
    )

    # one_second = 1_000_000_000

    # map_impl = Enum.at(output.scenarios, 1)

    # assert map_impl.run_time_data.statistics.average <= original.run_time_data.statistics.average
    # result = Enum.at(output, 1)
    #   assert result.run_time_data.statistics.average <= original.run_time_data.statistics.average
    # |> Enum.each(fn result ->
    # end)
  end
end
