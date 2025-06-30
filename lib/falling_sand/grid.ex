defmodule FallingSand.Grid do
  def tick(grid) do
    height = length(grid)
    width = length(hd(grid))
    empty_grid = for _ <- 1..height, do: for(_ <- 1..width, do: 0)

    Enum.reduce((height - 1)..0//-1, empty_grid, fn y, new_grid ->
      Enum.reduce(0..(width - 1), new_grid, fn x, new_grid ->
        cell = get(grid, x, y)

        cond do
          cell == :sand and get(grid, x, y + 1) == :empty ->
            new_grid
            |> set(x, y + 1, :sand)
            |> set(x, y, :empty)

          cell == :sand and get(grid, x + 1, y + 1) == :empty and get(grid, x + 1, y) == :empty ->
            new_grid
            |> set(x + 1, y + 1, :sand)
            |> set(x, y, :empty)

          cell == :sand and get(grid, x - 1, y + 1) == :empty and get(grid, x - 1, y) == :empty ->
            new_grid
            |> set(x - 1, y + 1, :sand)
            |> set(x, y, :empty)

          true ->
            set(new_grid, x, y, cell)
        end
      end)
    end)
  end

  def new(grid) do
    if Enum.all?(List.flatten(grid), fn element -> element in [:sand, :empty] end) do
      grid
    else
      raise "Attempted to create grid with invalid data."
    end
  end

  def empty(width, height) do
    for _y <- 0..(height - 1) do
      for _x <- 0..(width - 1) do
        :empty
      end
    end
  end

  def get(grid, x, y) do
    if in_bounds?(grid, x, y) do
      grid |> Enum.at(y) |> Enum.at(x)
    else
      :oob
    end
  end

  def in_bounds?([first_row | _] = grid, x, y) when is_list(first_row) do
    x >= 0 and y >= 0 and y < length(grid) and x < length(first_row)
  end

  def set(grid, x, y, value) when is_atom(value) do
    List.update_at(grid, y, fn row ->
      List.update_at(row, x, fn _ -> value end)
    end)
  end

  def pretty_print(grid) do
    IO.puts("==============")
    IO.puts("[")

    Enum.each(grid, fn row ->
      IO.inspect(row)
    end)

    IO.puts("]")

    IO.puts("==============")
  end

  def random(width, height) do
    for _y <- 0..(height - 1) do
      for _x <- 0..(width - 1) do
        Enum.random([:sand, :empty])
      end
    end
  end
end
