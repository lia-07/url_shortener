import gleam/erlang/process
import mist
import url_shortener/database
import url_shortener/router
import url_shortener/web
import wisp

pub const db_name = "db.sqlite3"

pub fn main() {
  wisp.configure_logger()

  // Wisp requires a secret key for cryptography purposes, even if you don't
  // need it
  let secret_key_base = wisp.random_string(64)

  // Configure the database connection and store it in our context variable so 
  // it can be used throughout the program
  let assert Ok(_) = database.with_connection(db_name, database.migrate_schema)
  use db <- database.with_connection(db_name)
  let context = web.Context(db)

  // Prepare and start serving the application
  let handler = router.handle_request(_, context)
  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  // When the response has been served, sleep the process
  process.sleep_forever()
}
