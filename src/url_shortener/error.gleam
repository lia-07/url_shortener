import sqlight

// types of app error
pub type AppError {
  NotFound
  MethodNotAllowed
  BadRequest
  UnprocessableEntity
  ContentRequired
  SqlightError(sqlight.Error)
}
