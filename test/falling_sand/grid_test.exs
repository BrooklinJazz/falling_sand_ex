defmodule FallingSand.GridTest do
  use ExUnit.Case
  alias FallingSand.Grid.WithDiffTracking
  alias FallingSand.Grid.WithActiveTracking
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

  test "tick/1 _ sand falls down" do
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

  test "tick/1 sand falls down in a line" do
    {all, active, diff} = grid = Grid.new()
    Grid.set(grid, {0, 0}, :sand)
    Grid.set(grid, {0, 1}, :sand)
    Grid.tick(grid)

    assert Grid.get(grid, {0, 0}) == :empty
    assert Grid.get(grid, {0, 1}) == :sand
    assert Grid.get(grid, {0, 2}) == :sand
  end

  test "tick/1 sand falls down right" do
    grid = Grid.new()
    Grid.set(grid, {1, 0}, :sand)
    Grid.set(grid, {0, 1}, :stone)
    Grid.set(grid, {1, 1}, :stone)

    Grid.tick(grid)
    assert Grid.get(grid, {2, 1}) == :sand
  end

  test "tick/1 sand falls down left" do
    grid = Grid.new()
    Grid.set(grid, {1, 0}, :sand)
    Grid.set(grid, {1, 1}, :stone)
    Grid.set(grid, {2, 1}, :stone)

    Grid.tick(grid)
    assert Grid.get(grid, {0, 1}) == :sand
  end

  test "tick/1 competing falling sand isn't lost" do
    grid = Grid.new()

    Grid.set(grid, {1, 0}, :sand)
    Grid.set(grid, {2, 0}, :sand)
    Grid.set(grid, {0, 1}, :stone)
    Grid.set(grid, {2, 1}, :stone)
    Grid.set(grid, {3, 1}, :ston)

    Grid.tick(grid)
    assert Grid.get(grid, {1, 1}) == :sand
    assert Grid.all_cells(grid) |> Enum.count() == 5
  end

  # caught an earlier bug
  test "tick/1 many grains" do
    {all_cells, active_cells, _diff} = grid = Grid.new()
    coordinates = Enum.map(1..50000, fn n -> {{n, 0}, :sand} end)

    Enum.each(coordinates, fn {coord, element} ->
      Grid.set(grid, coord, element)
    end)

    coord = {45203, 0}

    Enum.each(1..60, fn _ ->
      Grid.tick(grid)
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
        "Sand Particles" => Enum.map(1..1_000_000, fn n -> {{n, 0}, :sand} end),
        "Different Particles" =>
          Enum.map(1..1_000_000, fn n -> {{n, 0}, Enum.random([:sand, :stone])} end),
        "Same Particle" => Enum.map(1..1_000_000, fn _ -> {{0, 0}, :sand} end),
        # bulk insert should never be called with empty particles, so ignore its results on this case.
        "50K Empty Particle" => Enum.map(1..50000, fn n -> {{n, 0}, :empty} end)
      }
    )
  end

  @tag :benchmark
  @tag timeout: :infinity
  test "benchmark tick cycle" do
    size = 1000

    output =
      Benchee.run(
        %{
          "WithActiveTracking.tick/1" => {
            fn grid ->
              Enum.each(1..60, fn _ ->
                WithActiveTracking.tick(grid)
              end)
            end,
            before_scenario: fn coordinates ->
              grid = WithActiveTracking.new()

              Enum.each(coordinates, fn {coord, element} ->
                WithActiveTracking.set(grid, coord, element)
              end)

              grid
            end
          },
          "WithDiffTracking.tick/1" => {
            fn grid ->
              Enum.each(1..60, fn _ ->
                WithDiffTracking.tick(grid)
              end)
            end,
            before_scenario: fn coordinates ->
              grid = WithDiffTracking.new()

              Enum.each(coordinates, fn {coord, element} ->
                WithDiffTracking.set(grid, coord, element)
              end)

              grid
            end
          }
        },
        time: 2,
        memory_time: 1,
        save: [path: "bench/optimized_with_diff.exs"],
        inputs: %{
          "Horizonal Particles" => Enum.map(1..size, fn n -> {{n, 0}, :sand} end),
          "Sand Particles Fall then Idle" =>
            Enum.flat_map(1..size, fn n ->
              [{{n, 0}, :sand}, {{n, 2}, :stone}, {{n - 1, 2}, :stone}, {{n + 1, 2}, :stone}]
            end)
            |> Enum.uniq(),
          "Vertical" => Enum.map(1..size, fn n -> {{0, n}, :sand} end),
          "Spaced Vertical" => Enum.map(1..(size * 2)//2, fn n -> {{0, n}, :sand} end),
          "Diagonal Left" =>
            Enum.flat_map(1..size, fn n -> [{{n, n}, :sand}, {{n + 1, n + 1}, :stone}] end),
          "Diagonal Right" =>
            Enum.flat_map(1..size, fn n -> [{{-n, n}, :sand}, {{-n + 1, n + 1}, :stone}] end)
        }
      )

    # one_second = 1_000_000_000

    # grid_results = Enum.at(output.scenarios, 0)

    # # Should be able to simulate 50K particles at 60 frames in under one second.
    # assert grid_results.run_time_data.statistics.average <= one_second
  end
end
