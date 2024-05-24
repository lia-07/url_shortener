import gleam/string_builder
import gleam/string
import gleam/http.{Get, Post}
import gleam/io
import gleam/json.{array, bool, int, null, object, string}
import wisp.{type Request, type Response}
import url_shortener/link
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
    ["v1", ..endpoint] -> v1_api_handler(req, ctx, endpoint)
    _ ->
      wisp.not_found()
      |> wisp.json_body(
        object([
          #("success", bool(False)),
          #("error", string("Specified API version is invalid")),
        ])
        |> json.to_string_builder(),
      )
  }
}

fn v1_api_handler(req: Request, ctx, endpoint) {
  case endpoint {
    ["link"] -> v1_link_handler(req, ctx)
    _ -> {
      wisp.not_found()
      |> wisp.json_body(
        object([
          #("success", bool(False)),
          #("error", string("Unknown endpoint requested")),
        ])
        |> json.to_string_builder(),
      )
    }
  }
}

fn v1_link_handler(req: Request, ctx) {
  case req.method {
    Post -> link.shorten(req, ctx)
    Get -> link.info(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}
