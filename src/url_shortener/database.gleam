import gleam/result
import sqlight
import url_shortener/error.{type AppError}

pub fn with_connection(name: String, func: fn(sqlight.Connection) -> a) -> a {
  use db <- sqlight.with_connection(name)

  func(db)
}

pub fn migrate_schema(db: sqlight.Connection) -> Result(Nil, AppError) {
  sqlight.exec("", db)
  |> result.map_error(error.SqlightError)
}
