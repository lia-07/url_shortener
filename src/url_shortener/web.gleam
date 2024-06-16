import gleam/json.{type Json}
import sqlight
import wisp.{type Request, type Response}

// type contains our context constructor. currently only holds db connection
pub type Context {
  Context(db: sqlight.Connection)
}

// wisp stuff
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

// wrapper for json responses returned by the api. takes in http code, success 
// (cont.) boolean, and body content. responds with a json response
pub fn json_response(
  code code: Int,
  success success: Bool,
  body content: Json,
) -> Response {
  let body = case success {
    True -> #("response", content)
    False -> #("error", content)
  }
  wisp.response(code)
  |> wisp.json_body(
    json.object([#("success", json.bool(success)), body])
    |> json.to_string_builder(),
  )
}
