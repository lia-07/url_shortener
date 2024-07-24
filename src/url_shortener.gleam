import gleam/erlang/process
import mist
import url_shortener/database
import url_shortener/router
import url_shortener/web
import wisp

pub const db_name = "db.sqlite3"

pub fn main() {
  wisp.configure_logger()

  // required for cryptography purposes, even if you don't use it
  let secret_key_base = wisp.random_string(64)

  // configure the database connection and store it in a 'context' variable
  let assert Ok(_) = database.with_connection(db_name, database.migrate_schema)
  use db <- database.with_connection(db_name)
  let context = web.Context(db)

  // prepare and start serving the application
  let handler = router.handle_request(_, context)
  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http
  process.sleep_forever()
}
