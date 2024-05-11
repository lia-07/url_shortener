import gleam/string_builder
import gleam/string
import wisp.{type Request, type Response}
import url_shortener/web.{type Context}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    path ->
      wisp.ok()
      |> wisp.html_body(string_builder.from_string(
        "<h1>" <> string.concat(path) <> "</h1>",
      ))
  }
}
