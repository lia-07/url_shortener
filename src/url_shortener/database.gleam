import gleam/result
import sqlight
import url_shortener/error.{type AppError}

// connect to database and run a given function. 
// in the main function, we put in the below "migrate_schema" function
pub fn with_connection(name: String, func: fn(sqlight.Connection) -> a) -> a {
  use db <- sqlight.with_connection(name)

  func(db)
}

// set up the database
pub fn migrate_schema(db: sqlight.Connection) -> Result(Nil, AppError) {
  sqlight.exec(
    "
    PRAGMA journal_mode=WAL;
    CREATE TABLE IF NOT EXISTS links (
      back_half TEXT PRIMARY KEY NOT NULL,
      original_url TEXT NOT NULL,
      hits INTEGER UNSIGNED DEFAULT 0,
      created TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
    );
    ",
    db,
  )
  |> result.map_error(error.SqlightError)
}
