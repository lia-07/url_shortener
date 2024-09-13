import gleam/http
import gleam/json.{type Json}
import sqlight
import wisp.{type Request, type Response}

// type contains our context constructor. currently only holds db connection
pub type Context {
  Context(db: sqlight.Connection, static_path: String)
}

// reusable wrapper for json responses the api returns
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
  |> add_cors_headers
  |> wisp.json_body(
    json.object([#("success", json.bool(success)), body])
    |> json.to_string_builder(),
  )
}

// wisp middleware stuff
pub fn middleware(
  req: Request,
  ctx: Context,
  handle_request: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- handle_cors(req)
  use <- wisp.serve_static(req, under: "/_app", from: ctx.static_path)

  handle_request(req)
}

// cors functions, i hate cors
pub fn handle_cors(req: Request, handler: fn() -> Response) -> Response {
  case req.method {
    http.Options -> handle_preflight()
    _ -> add_cors_headers(handler())
  }
}

fn handle_preflight() -> Response {
  wisp.response(200)
  |> add_cors_headers
  |> wisp.set_header(
    "Access-Control-Allow-Methods",
    "GET, POST, PUT, DELETE, OPTIONS",
  )
  |> wisp.set_header("Access-Control-Allow-Headers", "Content-Type")
}

fn add_cors_headers(res: Response) -> Response {
  res
  |> wisp.set_header("Access-Control-Allow-Origin", "*")
  |> wisp.set_header("Access-Control-Allow-Credentials", "true")
}
