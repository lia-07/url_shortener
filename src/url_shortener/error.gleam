import gleam/json
import sqlight

// types of app error
pub type AppError {
  NotFound
  ContentRequired
  MethodNotAllowed
  Conflict
  BadRequest
  InvalidUrl
  JsonError(json.DecodeError)
  SqlightError(sqlight.Error)
}
