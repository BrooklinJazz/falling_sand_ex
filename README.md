# FallingSand (WIP)

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

## Elements

| Type      | Behavior                                        |
| --------- | ----------------------------------------------- |
| **Sand**  | Falls straight down, settles on solids          |
| **Water** | Flows down and sideways, fills gaps             |
| **Smoke** | Rises, dissipates over time                     |
| **Steam** | Rises quickly, condenses into water when cooled |
| **Fire**  | Spreads to flammable materials, burns out       |

## Dev Notes
* ChunkServer
* Drag Screen Coordinates
* Color Sand
* Select Element Type
* Pretty Cursor
* Refactor and Optimize Grid
* Paint other player cursors

## Optmization
The broadcasting of many messages from the GenServer introduces a massive delay and overhead.
The Tick takes only 5ms or so, but the broadcast can take upwards of 300ms or more.

Options:
* Instead of a Broadcast, have LiveViews read directly from the ets grid
* 