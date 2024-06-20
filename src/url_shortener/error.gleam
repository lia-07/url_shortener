import sqlight

// types of app error
pub type AppError {
  NotFound
  MethodNotAllowed
  Conflict
  BadRequest
  UnprocessableEntity
  ContentRequired
  SqlightError(sqlight.Error)
}
