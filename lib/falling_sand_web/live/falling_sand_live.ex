defmodule FallingSandWeb.FallingSandLive do
  alias FallingSand.Grid
  use FallingSandWeb, :live_view

  def mount(_params, _session, socket) do
    height = 100
    width = 100
    grid = Grid.empty(width, height)
    cell_size = 6

    socket = push_event(socket, "render_grid", %{grid: grid})

    if connected?(socket) do
      Process.send(self(), :tick, [])
    end

    {:ok,
     assign(socket,
       grid: grid,
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
    updated_grid = Grid.tick(socket.assigns.grid)

    socket =
      push_event(socket, "render_grid", %{grid: updated_grid}) |> assign(grid: updated_grid)

    {:noreply, socket}
  end

  def handle_event("click_pixel", %{"x" => x, "y" => y}, socket) do
    # Update simulation: place sand, stone, etc.
    updated_grid = Grid.set(socket.assigns.grid, x, y, :sand)

    socket =
      push_event(socket, "render_grid", %{grid: updated_grid}) |> assign(grid: updated_grid)

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
    updated_grid =
      if socket.assigns.is_drawing do
        Grid.set(socket.assigns.grid, socket.assigns.cursor_x, socket.assigns.cursor_y, :sand)
      else
        socket.assigns.grid
      end

    updated_grid = Grid.tick(updated_grid)

    socket =
      push_event(socket, "render_grid", %{grid: updated_grid}) |> assign(grid: updated_grid)

    Process.send_after(self(), :tick, 10)
    {:noreply, socket}
  end
end
