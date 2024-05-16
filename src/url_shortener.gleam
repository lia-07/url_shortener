import gleam/erlang/process
import gleam/io
import gleam/int
import gleam/list
import wisp
import mist
import birl
import birl/duration.{type Duration, type Unit}
import url_shortener/router
import url_shortener/database
import url_shortener/link
import url_shortener/web

pub const db_name = "db.sqlite3"

fn x_times(x, f: fn(Int) -> String) {
  case x {
    0 -> f(5)
    _ -> {
      f(5)
      x_times(x - 1, f)
    }
  }
}

type Trial {
  Trial(generator: String, duration: Int)
}

const times = 100_000

pub fn main() {
  let trials: List(Trial) = []

  io.print("\nNanoid-based generator:\n")
  let start = birl.now()
  x_times(times, link.random_back_half_from_nanoid)
  let end = birl.now()
  let length =
    birl.difference(end, start)
    |> duration.blur_to(Unit.Second)
  let trials =
    trials
    |> list.append([Trial("Nanoid", length)])

  io.print("\nCrypto and Base64-based generator:\n")
  let start = birl.now()
  x_times(times, link.random_back_half_from_crypto)
  let end = birl.now()
  let duration = birl.difference(end, start)
  let trials =
    trials
    |> list.append([Trial("Crypto/Base64", duration)])

  io.print("\nRandom list-based generator:\n")
  let start = birl.now()
  x_times(times, link.random_back_half_from_random_list)
  let end = birl.now()
  let duration = birl.difference(end, start)
  let trials =
    trials
    |> list.append([Trial("Random List", duration)])

  io.print("\nFinal Results:")
  io.debug(trials)
  wisp.configure_logger()

  let secret_key_base = wisp.random_string(64)

  let assert Ok(_) = database.with_connection(db_name, database.migrate_schema)

  use db <- database.with_connection(db_name)

  let context = web.Context(db)

  let handler = router.handle_request(_, context)

  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
