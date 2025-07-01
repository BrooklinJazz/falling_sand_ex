defmodule FallingSandWeb.FallingSandLive.ETS do
  alias FallingSand.GridServer
  alias FallingSand.Grid
  use FallingSandWeb, :live_view

  def mount(_params, _session, socket) do
    height = 100
    width = 100
    cell_size = 5
    page_id = UUID.uuid1()

    if connected?(socket) do
      Phoenix.PubSub.subscribe(FallingSand.PubSub, "grid")
    end

    socket = push_event(socket, "render_grid", %{active_cells: Grid.active_cells()})

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

  def handle_event("click_pixel", %{"x" => x, "y" => y}, socket) do
    {:noreply, socket}
  end

  def handle_event("mouseup", _, socket) do
    GenServer.cast(GridServer, {:mouseup, %{page_id: socket.assigns.page_id}})
    {:noreply, assign(socket, is_drawing: false)}
  end

  def handle_event("mousedown", %{"x" => x, "y" => y}, socket) do
    # It's a bit hacky calling GenServer directly here
    GenServer.cast(GridServer, {:mousedown, %{x: x, y: y, page_id: socket.assigns.page_id}})
    {:noreply, assign(socket, cursor_x: x, cursor_y: y, is_drawing: true)}
  end

  def handle_event("mousemove", %{"x" => x, "y" => y}, socket) do
    GenServer.cast(GridServer, {:mousemove, %{x: x, y: y, page_id: socket.assigns.page_id}})
    {:noreply, assign(socket, cursor_x: x, cursor_y: y)}
  end

  def handle_info({:diffs, active_cells}, socket) do
    {:noreply, push_event(socket, "render_grid", %{active_cells: active_cells})}
  end
end
