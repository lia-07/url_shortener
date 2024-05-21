import gleam/erlang/process
import gleam/io
import gleam/int
import gleam/list
import wisp
import mist
import birl
import birl/duration
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
  Trial(generator: String, duration: Float)
}

const times = 1_000_000

pub fn main() {
  let trials: List(Trial) = []

  io.print("\nNanoid-based generator:\n")
  let start = birl.now()
  x_times(times, link.random_back_half_from_nanoid)
  let end = birl.now()
  let length =
    birl.difference(end, start)
    |> duration.blur_to(duration.MilliSecond)
  let trials =
    trials
    |> list.append([Trial("Nanoid", { int.to_float(length) /. 1000.0 })])

  io.print("\nCrypto and Base64-based generator:\n")
  let start = birl.now()
  x_times(times, link.random_back_half_from_crypto)
  let end = birl.now()
  let length =
    birl.difference(end, start)
    |> duration.blur_to(duration.MilliSecond)
  let trials =
    trials
    |> list.append([Trial("Crypto/Base64", int.to_float(length) /. 1000.0)])

  io.print("\nRandom list-based generator:\n")
  let start = birl.now()
  x_times(times, link.random_back_half_from_random_list)
  let end = birl.now()
  let length =
    birl.difference(end, start)
    |> duration.blur_to(duration.MilliSecond)
  let trials =
    trials
    |> list.append([
      Trial("Random list-based", { int.to_float(length) /. 1000.0 }),
    ])

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
