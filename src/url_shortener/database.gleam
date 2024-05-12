import gleam/result
import sqlight
import url_shortener/error.{type AppError}

pub fn with_connection(name: String, func: fn(sqlight.Connection) -> a) -> a {
  use db <- sqlight.with_connection(name)

  func(db)
}

pub fn migrate_schema(db: sqlight.Connection) -> Result(Nil, AppError) {
  sqlight.exec(
    "
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
