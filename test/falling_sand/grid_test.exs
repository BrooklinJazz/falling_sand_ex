defmodule FallingSand.GridTest do
  use ExUnit.Case
  # alias FallingSand.Grid
  alias FallingSand.Grid
  @size Application.compile_env!(:falling_sand, :grid_size)
  @min 0

  test "all_cells/1" do
    grid = Grid.new()
    Grid.set(grid, {0, 1}, :sand)
    assert [[0, 1, :sand]] = Grid.all_cells(grid)
  end

  test "get/2" do
    grid = Grid.new()

    assert Grid.get(grid, {0, 0}) == :empty
  end

  test "set/3 sand" do
    grid = Grid.new()
    Grid.set(grid, {0, 0}, :sand)
    assert Grid.get(grid, {0, 0}) == :sand
  end

  test "set/3 stone" do
    grid = Grid.new()
    Grid.set(grid, {0, 0}, :stone)
    assert Grid.get(grid, {0, 0}) == :stone
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
    Grid.set(grid, {3, 1}, :stone)

    Grid.tick(grid)
    assert Grid.get(grid, {1, 1}) == :sand
    assert Grid.all_cells(grid) |> Enum.count() == 5
  end

  test "tick/1 sand falling diffs" do
    grid = Grid.new()
    Grid.set(grid, {0, 0}, :sand)
    diffs = Grid.tick(grid)
    assert [0, 0, :empty] in diffs
    assert [0, 1, :sand] in diffs
  end

  test "tick/1 stone set diff" do
    grid = Grid.new()
    Grid.set(grid, {0, 0}, :stone)
    diffs = Grid.tick(grid)
    assert [0, 0, :stone] in diffs
  end

  test "set/3 sand beyond edges of grid size" do
    grid = Grid.new()
    Grid.set(grid, {-1, 0}, :sand)
    Grid.set(grid, {0, -1}, :sand)
    Grid.set(grid, {@size, @size + 1}, :sand)
    Grid.set(grid, {@size + 1, @size}, :sand)
    assert Grid.get(grid, {-1, 0}) == :empty
    assert Grid.get(grid, {0, -1}) == :empty
    assert Grid.get(grid, {@size, @size + 1}) == :empty
    assert Grid.get(grid, {@size + 1, @size}) == :empty
  end

  test "grid tracks diff history based on tick number" do
    grid = Grid.new()
    Grid.set(grid, {0, 0}, :sand)
    Grid.tick(grid, 0)
    Grid.tick(grid, 1)
    Grid.tick(grid, 2)
    # assert [[0, 0, :sand]] = Grid.diffs(grid, 0)
    assert [[0, 0, :empty], [0, 1, :sand]] = Grid.diffs(grid, 0)
    assert [[0, 1, :empty], [0, 2, :sand]] = Grid.diffs(grid, 1)
    assert [[0, 2, :empty], [0, 3, :sand]] = Grid.diffs(grid, 2)

    assert [
             [0, 0, :empty],
             [0, 1, :sand],
             [0, 1, :empty],
             [0, 2, :sand],
             [0, 2, :empty],
             [0, 3, :sand]
           ] =
             Grid.diffs_since(grid, 0)

    assert [[0, 1, :empty], [0, 2, :sand], [0, 2, :empty], [0, 3, :sand]] =
             Grid.diffs_since(grid, 1)
  end

  @tag :skip
  test "tick/1 sand falls beyond edges of grid size" do
    grid = Grid.new()
    Grid.set(grid, {@min, @size}, :sand)
    Grid.set(grid, {@size, @size}, :sand)
    diffs = Grid.tick(grid)
    assert {{@size, @size}, :empty} in diffs
    assert {{@min, @size}, :empty} in diffs
    assert Grid.get(grid, {0, @size + 1}) == :empty
    assert Grid.get(grid, {@size, @size + 1}) == :empty
  end

  @tag :skip
  test "tick/1 sand doesn't get stuck if cells below are removed"

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
    output =
      Benchee.run(
        %{
          "Grid.tick/1" => {
            fn grid ->
              Enum.each(1..60, fn _ ->
                Grid.tick(grid)
              end)
            end,
            before_scenario: fn coordinates ->
              grid = Grid.new()

              Enum.each(coordinates, fn {coord, element} ->
                Grid.set(grid, coord, element)
              end)

              grid
            end,
            after_scenario: fn grid ->
              :ets.delete(grid)
            end
          }
        },
        time: 2,
        memory_time: 1,
        # save: [path: "bench/grid.benchee"],
        # load: "bench/grid*.benchee",
        inputs: %{
          # alternating rows of falling sand
          "Max" =>
            Enum.flat_map(0..@size//2, fn y -> Enum.map(0..@size, fn x -> {{x, y}, :sand} end) end)
          # "Sand Particles Fall then Idle" =>
          #   Enum.flat_map(1..@size, fn n ->
          #     [{{n, 0}, :sand}, {{n, 2}, :stone}, {{n - 1, 2}, :stone}, {{n + 1, 2}, :stone}]
          #   end)
          #   |> Enum.uniq()
          # "Horizonal" => Enum.map(1..@size, fn n -> {{n, 0}, :sand} end),
          # "Vertical" => Enum.map(1..@size, fn n -> {{0, n}, :sand} end),
          # "Spaced Vertical" => Enum.map(1..(@size * 2)//2, fn n -> {{0, n}, :sand} end),
          # "Diagonal Left" =>
          #   Enum.flat_map(1..@size, fn n -> [{{n, n}, :sand}, {{n + 1, n + 1}, :stone}] end),
          # "Diagonal Right" =>
          #   Enum.flat_map(1..@size, fn n -> [{{-n, n}, :sand}, {{-n + 1, n + 1}, :stone}] end)
        }
      )

    one_second = 1_000_000_000

    grid_results = Enum.at(output.scenarios, 0)

    # Should be able to simulate max particles at 60 frames in under one second.
    assert grid_results.run_time_data.statistics.average <= one_second
  end

  # Used this to understand the performance cost of storing data in two different :ets tables with tab2list vs one table then using select
  @tag :benchmark
  @tag :infinity
  test ":ets.tab2list vs :ets.select with active boolean" do
    size = 1_000_000

    Benchee.run(%{
      ":ets.tab2list" =>
        {fn table ->
           :ets.tab2list(table)
         end,
         before_scenario: fn _ ->
           table = :ets.new(:table, [:ordered_set, :public])

           for n <- 1..div(size, 2) do
             :ets.insert(table, {{n, n}, {true, :sand}})
           end

           table
         end},
      ":ets.select" => {
        fn table ->
          :ets.match(table, {{:"$1", :"$2"}, {true, :"$3"}})
        end,
        before_scenario: fn _ ->
          table = :ets.new(:table, [:ordered_set, :public])

          for n <- 1..size do
            :ets.insert(table, {{n, n}, {rem(n, 2) == 0, :sand}})
          end

          table
        end
      }
    })
  end
end
