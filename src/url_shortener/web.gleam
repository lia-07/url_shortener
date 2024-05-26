import gleam/json.{type Json}
import wisp.{type Request, type Response}
import sqlight

pub type Context {
  Context(db: sqlight.Connection)
}

pub fn middleware(
  req: Request,
  handle_request: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  handle_request(req)
}

pub fn json_response(code: Int, success: Bool, body: Json) -> Response {
  wisp.response(code)
  |> wisp.json_body(
    json.object([#("success", json.bool(success)), #("error", body)])
    |> json.to_string_builder(),
  )
}
