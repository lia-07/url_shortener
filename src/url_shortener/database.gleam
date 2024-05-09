import gleam/result
import sqlight
import url_shortener/error.{type AppError}

pub fn with_connection(name: String, func: fn(sqlight.Connection) -> a) -> a {
  use db <- sqlight.with_connection(name)

  func(db)
}

pub fn migrate_schema(db: sqlight.Connection) -> Result(Nil, AppError) {
  sqlight.exec(
    "CREATE TABLE IF NOT EXISTS names (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL CHECK(length(name) > 0)
    );",
    db,
  )
  |> result.map_error(error.SqlightError)
}
