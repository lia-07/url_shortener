import sqlight

pub type AppError {
  NotFound
  MethodNotAllowed
  BadRequest
  UnprocessableEntity
  ContentRequired
  SqlightError(sqlight.Error)
}
