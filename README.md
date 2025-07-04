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

* Make GridServer only manage specific coordinates
* Only broadcast diffs
* Limit active cells to only those likely to change.
* Store all cells vs active cells in different places?
* Users can drag the screen to move their page coordinate
* Users subscribe to broadcasted events only for their page coordinates?
* Scale with a dns cluster?

* GridServer
  * ActiveCells
  * tick -> broadcast diffs only to the chunk coords
  * 