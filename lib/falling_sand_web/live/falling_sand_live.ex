defmodule FallingSandWeb.FallingSandLive do
  alias FallingSand.Grid
  alias FallingSand.GridServer
  use FallingSandWeb, :live_view
  @size Application.compile_env!(:falling_sand, :grid_size)
  @draw_radius Application.compile_env!(:falling_sand, :draw_radius)
  @cell_size Application.compile_env!(:falling_sand, :cell_size)

  def mount(_params, _session, socket) do
    height = @size
    width = @size
    cell_size = @cell_size
    page_id = UUID.uuid1()

    if connected?(socket) do
      Process.send_after(self(), :tick, 15)
      Phoenix.PubSub.subscribe(FallingSand.PubSub, "grid")
    end

    socket = push_event(socket, "re-render", %{all_cells: Grid.all_cells(Grid)})

    {:ok,
     assign(socket,
       element: :sand,
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
    <section class="max-w-fit h-screen mx-auto flex flex-col justify-center">
      <canvas
        class="border-2 border-gray-500 border-dotted"
        id="pixel-canvas"
        phx-hook="PixelCanvas"
        cellSize={@cell_size}
        height={@height}
        width={@width}
      >
      </canvas>
      <article class="mt-1">
        <.button phx-click="select-element:sand">Sand</.button>
        <.button phx-click="select-element:stone">Stone</.button>
      </article>
    </section>
    """
  end

  def handle_event("set", %{"x" => x, "y" => y}, socket) do
    Grid.set(Grid, {x, y}, socket.assigns.element)

    r = @draw_radius

    case socket.assigns.element do
      :sand ->
        for xr <- (x - r)..(x + r), yr <- (y - r)..(y + r) do
          {xr, yr}
        end
        # |> Enum.shuffle()
        # |> Enum.take(5)
        |> Enum.each(fn {x, y} ->
          Grid.set(Grid, {x, y}, :sand)
        end)

      :stone ->
        for xr <- (x - r)..(x + r), yr <- (y - r)..(y + r) do
          {xr, yr}
          Grid.set(Grid, {xr, yr}, :stone)
        end
    end

    {:noreply, socket}
  end

  def handle_event("select-element:" <> element, _params, socket) do
    {:noreply, assign(socket, element: String.to_existing_atom(element))}
  end

  # def handle_info({:diffs, diffs}, socket) do
  #   {:noreply, push_event(socket, "re-render", %{all_: diffs})}
  # end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 15)
    all_cells = Grid.all_cells(Grid)
    {:noreply, push_event(socket, "re-render", %{all_cells: all_cells})}
  end
end
