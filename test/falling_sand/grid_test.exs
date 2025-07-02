defmodule FallingSand.GridTest do
  use ExUnit.Case
  doctest FallingSand.Grid
  alias FallingSand.Grid.ETS, as: Grid
  alias FallingSand.Grid.ETS
  alias FallingSand.Grid.MapImpl

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

  test "tick/1 sand falls" do
    grid = Grid.new()
    grid = Grid.set(grid, {0, 0}, :sand)
    grid = Grid.tick(grid)
    assert Grid.get(grid, {0, 0}) == :empty
    assert Grid.get(grid, {0, 1}) == :sand
  end

  test "tick/1 sand stops when blocked" do
    grid = Grid.new()
    grid = Grid.set(grid, {1, 0}, :sand)
    grid = Grid.set(grid, {0, 1}, :stone)
    grid = Grid.set(grid, {1, 1}, :stone)
    grid = Grid.set(grid, {2, 1}, :stone)
    grid = Grid.tick(grid)

    assert Grid.get(grid, {1, 0}) == :sand
    assert Grid.get(grid, {0, 1}) == :stone
    assert Grid.get(grid, {1, 1}) == :stone
    assert Grid.get(grid, {2, 1}) == :stone
  end

  @tag :skip
  test "tick/1 sand stops at edges? I'm not sure if this will be needed if I do an infinite sim..."

  @tag timeout: :infinity
  @tag :benchmark
  test "benchmark Grid.set/3" do
    Benchee.run(
      %{
        "ETS" => fn coordinates ->
          grid = ETS.new()

          Enum.reduce(coordinates, grid, fn coord, new_grid ->
            ETS.set(new_grid, coord, :sand)
          end)
        end,
        "MapImpl" => fn coordinates ->
          grid = MapImpl.new()

          Enum.reduce(coordinates, grid, fn coord, new_grid ->
            MapImpl.set(new_grid, coord, :sand)
          end)
        end
      },
      inputs: %{
        "sample" => generate_coords(100_000)
      }
    )
  end

  @tag :benchmark
  test "benchmark get/3" do
    coordinates = generate_coords(1000)

    ets_grid =
      Enum.reduce(coordinates, Grid.ETS.new(), fn coord, new_grid ->
        Grid.ETS.set(new_grid, coord, :sand)
      end)

    maps_grid =
      Enum.reduce(coordinates, Grid.Maps.new(), fn coord, new_grid ->
        Grid.Maps.set(new_grid, coord, :sand)
      end)

    Benchee.run(%{
      "ETS" => fn ->
        Enum.each(coordinates, fn coord ->
          Grid.ETS.get(ets_grid, coord)
        end)
      end,
      "Maps" => fn ->
        Enum.each(coordinates, fn coord ->
          Grid.Maps.get(maps_grid, coord)
        end)
      end
    })
  end

  @tag :benchmark
  @tag timeout: :infinity
  test "benchmark Grid.tick/1" do
    output =
      Benchee.run(
        %{
          "ETS" => fn {coordinates, frames} ->
            grid = Grid.ETS.new()

            grid =
              Enum.reduce(coordinates, grid, fn coord, new_grid ->
                Grid.ETS.set(new_grid, coord, :sand)
              end)

            grid =
              Enum.reduce(1..frames, grid, fn _, new_grid ->
                new_grid = Grid.tick(new_grid)
                Grid.ETS.all_cells(new_grid)
                new_grid
              end)
          end,
          "Maps" => fn {coordinates, frames} ->
            grid = Grid.Maps.new()

            grid =
              Enum.reduce(coordinates, grid, fn coord, new_grid ->
                Grid.Maps.set(new_grid, coord, :sand)
              end)

            grid =
              Enum.reduce(1..frames, grid, fn _, new_grid ->
                Grid.Maps.tick(grid)
                Grid.Maps.all_cells(new_grid)
                new_grid
              end)
          end
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

    one_second = 1_000_000_000

    original = Enum.at(output.scenarios, 0)
    map_impl = Enum.at(output.scenarios, 1)

    assert map_impl.run_time_data.statistics.average <= original.run_time_data.statistics.average
  end

  defp generate_coords(size) do
    for n <- 1..size do
      {Enum.random(1..(size * 1000)), Enum.random(1..(size * 1000))}
    end
  end
end
