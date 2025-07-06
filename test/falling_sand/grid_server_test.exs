defmodule FallingSand.GridServerTest do
  use ExUnit.Case
  doctest FallingSand.GridServer
  alias FallingSand.GridServer
  alias FallingSand.Grid
  @size Application.compile_env!(:falling_sand, :grid_size)

  test "grid server" do
    grid = Grid.new()
    {:ok, pid} = GridServer.start_link(tick: nil, grid: grid)
    Phoenix.PubSub.subscribe(FallingSand.PubSub, "grid")

    Grid.set(grid, {0, 0}, :sand)
    send(pid, :tick)
    assert_receive {:diffs, messages}

    assert [0, 1, :sand] in messages
    assert [0, 0, :empty] in messages
  end

  test "broadcasts diffs to multiple subscribers" do
    grid = Grid.new()
    {:ok, server} = GridServer.start_link(tick: nil, grid: grid)

    parent = self()

    subscriber_pids =
      for _ <- 1..1000 do
        spawn(fn ->
          Phoenix.PubSub.subscribe(FallingSand.PubSub, "grid")

          Phoenix.Tracker.track(FallingSand.Tracker, self(), "grid", "someid", %{
            pid: self(),
            notify: parent
          })

          # Wait for diff message
          receive do
            {:diffs, messages} -> send(parent, {:received_diff, self(), messages})
          end
        end)
      end

    # Mack sure pids are subscribed using FallingSand.Tracker
    Enum.each(subscriber_pids, fn _ ->
      assert_receive {:subscribed, _pid}, 500
    end)

    # Now safely trigger tick (all subscribers ready)
    start = System.monotonic_time(:microsecond)

    coordinates =
      Enum.flat_map(0..@size//2, fn row -> Enum.map(1..@size, fn x -> {{x, row}, :sand} end) end)

    Enum.map(coordinates, fn {{x, y} = coord, element} ->
      Grid.set(grid, coord, element)
      [x, y, element]
    end)

    send(server, :tick)

    Enum.each(subscriber_pids, fn _ ->
      assert_receive {:received_diff, _pid, _diff}, 1000
    end)

    finish = System.monotonic_time(:microsecond)
    elapsed_ms = (finish - start) / 1000
    fps = elapsed_ms / 1000 * 60
    IO.puts("Total tick + broadcast + receive time: #{elapsed_ms} ms")
    IO.puts("Estimated FPS: #{fps} s")

    GenServer.stop(server)
  end

  # @tag :benchmark
  # @tag timeout: :infinity
  # test "benchmark GridServer tick cycle" do
  #   parent = self()

  #   output =
  #     Benchee.run(
  #       %{
  #         "tick" => {
  #           fn {server, grid} ->
  #             parent = self()

  #             subscriber_pids =
  #               for _ <- 1..3 do
  #                 spawn(fn ->
  #                   Phoenix.PubSub.subscribe(FallingSand.PubSub, "grid")
  #                   # Notify parent process that this subscriber is ready
  #                   IO.inspect(self(), label: "SENDING READY TO PARENT")
  #                   Process.sleep(100)
  #                   send(parent, :ready)
  #                   # Wait for diff message
  #                   receive do
  #                     {:diffs, messages} ->
  #                       # Maybe I need to unsubscribe for future tests
  #                       # Phoenix.PubSub.unsubscribe(FallingSand.PubSub, "grid")
  #                       IO.inspect(self(), label: "SENDING DFF TO PARENT")
  #                       Process.sleep(100)
  #                       send(parent, {:received_diff, messages})
  #                   end
  #                 end)
  #               end

  #             # Wait for all subscribers to be ready before triggering tick
  #             Enum.each(subscriber_pids, fn sub_pid ->
  #               IO.inspect(sub_pid, label: "PARENT RECIEVED READY")

  #               receive do
  #                 :ready -> nil
  #               end
  #             end)

  #             IO.inspect(self())
  #             # Now safely trigger tick (all subscribers ready)
  #             send(server, :tick)

  #             # Wait for all subscribers to recieve the message.

  #             Enum.each(subscriber_pids, fn sub_pid ->
  #               IO.inspect(sub_pid, label: "WAITING")

  #               receive do
  #                 {:received_diff, messages} -> nil
  #               end

  #               alrighty = true
  #             end)

  #             IO.inspect("FINISHED")
  #           end,
  #           before_scenario: fn coordinates ->
  #             grid = Grid.new()

  #             Enum.each(coordinates, fn {coord, element} ->
  #               Grid.set(grid, coord, element)
  #             end)

  #             {:ok, server} = GridServer.start_link(tick: nil, grid: grid)
  #             {server, grid}
  #           end,
  #           after_scenario: fn {server, grid} ->
  #             # I Think the second time it makes pids, they don't receive the messages
  #             GenServer.stop(server)
  #           end
  #         }
  #       },
  #       time: 2,
  #       memory_time: 1,
  #       save: [path: "bench/grid_server.benchee"],
  #       load: "bench/grid_server*.benchee",
  #       inputs: %{
  #         "Horizonal" =>
  #       }
  #     )

  #   # one_second = 1_000_000_000

  #   # grid_results = Enum.at(output.scenarios, 0)

  #   # # # Should be able to simulate 50K particles at 60 frames in under one second.
  #   # assert grid_results.run_time_data.statistics.average <= one_second
  # end
end
