defmodule FallingSandWeb.FallingSandLive do
  alias FallingSand.Grid
  alias FallingSand.GridServer
  use FallingSandWeb, :live_view
  @size 100

  def mount(_params, _session, socket) do
    height = @size
    width = @size
    cell_size = 5
    page_id = UUID.uuid1()

    if connected?(socket) do
      Phoenix.PubSub.subscribe(FallingSand.PubSub, "grid")
    end

    socket = push_event(socket, "render_grid", %{diffs: GridServer.all_cells()})

    {:ok,
     assign(socket,
       height: height * cell_size,
       width: width * cell_size,
       cell_size: cell_size,
       cursor_x: 0,
       cursor_y: 0,
       is_drawing: false,
       page_id: page_id
     )}
  end

  def render(assigns) do
    ~H"""
    <h1>Falling Sand Sim</h1>
    <canvas
      id="pixel-canvas"
      phx-hook="PixelCanvas"
      cellSize={@cell_size}
      height={@height}
      width={@width}
    >
    </canvas>
    <hr />
    """
  end

  def handle_event("set", %{"x" => x, "y" => y}, socket) do
    Grid.set(:grid, {x, y}, :sand)
    {:noreply, socket}
  end

  def handle_info({:diffs, diffs}, socket) do
    {:noreply, push_event(socket, "render_grid", %{diffs: diffs})}
  end
end
