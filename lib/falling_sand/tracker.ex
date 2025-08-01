defmodule FallingSand.Tracker do
  use Phoenix.Tracker

  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)
    Phoenix.Tracker.start_link(__MODULE__, opts, opts)
  end

  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{pubsub_server: server, node_name: Phoenix.PubSub.node_name(server)}}
  end

  def handle_diff(diff, state) do
    for {topic, {joins, leaves}} <- diff do
      for {key, meta} <- joins do
        send(meta.notify, {:subscribed, meta.pid})
      end

      for {key, meta} <- leaves do
        # IO.puts("tracked pid left PubSub: key \"#{key}\" with meta #{inspect(meta)}")
      end
    end

    {:ok, state}
  end
end
