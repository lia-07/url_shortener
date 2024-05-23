import gleam/string_builder
import gleam/string
import gleam/json.{array, bool, int, null, object, string}
import wisp.{type Request, type Response}
import url_shortener/web.{type Context}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["api", ..version] -> api_version_handler(req, ctx, version)
    path ->
      wisp.ok()
      |> wisp.html_body(string_builder.from_string(
        "<h1>" <> string.concat(path) <> "</h1>",
      ))
  }
}

fn api_version_handler(req, ctx, version) {
  case version {
    ["v1", ..endpoint] -> api_v1_handler(req, ctx, endpoint)
    _ ->
      wisp.not_found()
      |> wisp.json_body(
        json.to_string_builder(
          object([
            #("success", bool(False)),
            #("error", string("Specified API version is invalid")),
          ]),
        ),
      )
  }
}

fn api_v1_handler(req, ctx, endpoint) {
  wisp.ok()
  |> wisp.json_body(
    json.to_string_builder(
      object([#("success", bool(True)), #("response", string("hi"))]),
    ),
  )
}
