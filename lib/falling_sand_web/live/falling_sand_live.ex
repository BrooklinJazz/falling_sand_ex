defmodule FallingSandWeb.FallingSandLive.ETS do
  alias FallingSand.Grid
  use FallingSandWeb, :live_view
  @framerate 15

  def mount(_params, _session, socket) do
    height = 100
    width = 100
    cell_size = 5

    if connected?(socket) do
      Process.send(self(), :tick, [])
    end

    Grid.new(width, height)

    for x <- 0..(width - 1) do
      Grid.set({x, height - 1}, :stone)
    end

    for y <- 0..(width - 1) do
      Grid.set({0, y}, :stone)
      Grid.set({width - 1, y}, :stone)
    end

    socket = push_event(socket, "render_grid", %{active_cells: Grid.active_cells()})

    {:ok,
     assign(socket,
       height: height * cell_size,
       width: width * cell_size,
       cell_size: cell_size,
       cursor_x: 0,
       cursor_y: 0,
       is_drawing: false
     )}
  end

  def render(assigns) do
    ~H"""
    <canvas
      id="pixel-canvas"
      phx-hook="PixelCanvas"
      cellSize={@cell_size}
      height={@height}
      width={@width}
    >
    </canvas>
    <button phx-click="tick">TICK</button>
    """
  end

  def handle_event("tick", _params, socket) do
    Grid.tick()

    socket = push_event(socket, "render_grid", %{active_cells: Grid.active_cells()})

    {:noreply, socket}
  end

  def handle_event("click_pixel", %{"x" => x, "y" => y}, socket) do
    Grid.set({x, y}, :sand)

    socket = push_event(socket, "render_grid", %{active_cells: Grid.active_cells()})

    {:noreply, socket}
  end

  def handle_event("mouseup", _, socket) do
    {:noreply, assign(socket, is_drawing: false)}
  end

  def handle_event("mousedown", %{"x" => x, "y" => y}, socket) do
    {:noreply, assign(socket, cursor_x: x, cursor_y: y, is_drawing: true)}
  end

  def handle_event("mousemove", %{"x" => x, "y" => y}, socket) do
    {:noreply, assign(socket, cursor_x: x, cursor_y: y)}
  end

  def handle_info(:tick, socket) do
    if socket.assigns.is_drawing do
      Grid.set({socket.assigns.cursor_x, socket.assigns.cursor_y}, :sand)
    end

    Grid.tick()

    socket = push_event(socket, "render_grid", %{active_cells: Grid.active_cells()})

    Process.send_after(self(), :tick, @framerate)
    {:noreply, socket}
  end
end
