import gleam/string_builder
import wisp.{type Request, type Response}
import url_shortener/web

pub fn handle_request(req: Request) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> {
      "<h1>There's nothing here. Try visiting <code>/name/:yourname</code> for a present."
      |> string_builder.from_string()
      |> wisp.html_response(200)
    }
    ["name"] -> {
      "<h1>So you're not going to tell me your name? Try visiting <code>/name/:yourname</code>.</h1>"
      |> string_builder.from_string()
      |> wisp.html_response(400)
    }
    ["name", name] -> {
      { "<h1>Hi " <> name <> "!</h1><br><p>Here is a present: &#127873;</p>" }
      |> string_builder.from_string()
      |> wisp.html_response(200)
    }
    _ -> wisp.not_found()
  }
}
