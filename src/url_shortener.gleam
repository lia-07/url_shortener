import gleam/io
import gleam/erlang/process
import wisp
import mist
import url_shortener/router
import url_shortener/database

pub const db_name = "db.sqlite3"

pub fn main() {
  wisp.configure_logger()

  // server configuration
  let secret_key_base = wisp.random_string(64)

  // immediately fail if we can't connect to the database
  let assert Ok(_) = database.with_connection(db_name, database.migrate_schema)

  use db <- database.with_connection(db_name)

  let handler = router.handle_request(_)

  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
