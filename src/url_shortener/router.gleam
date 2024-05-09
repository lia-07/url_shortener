import gleam/string_builder
import wisp.{type Request, type Response}
import url_shortener/web.{type Context}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> {
      wisp.ok()
      |> wisp.html_body(string_builder.from_string(
        "<h1>There's nothing here. Try visiting <code>/name/:yourname</code> for a present. <img alt=\"200: Ok\" src=\"https://http.cat/200\">",
      ))
    }
    ["name"] -> {
      wisp.bad_request()
      |> wisp.html_body(string_builder.from_string(
        "<h1>So you're not going to tell me your name? Try visiting <code>/name/:yourname</code>.</h1><img alt=\"Error 400: Bad Request\" src=\"https://http.cat/400\">",
      ))
    }
    ["name", name] -> {
      wisp.ok()
      |> wisp.html_body(string_builder.from_string(
        "<h1>Hi "
        <> name
        <> "!</h1><p>Here is a present: &#127873;</p> <img alt=\"200: Ok\" src=\"https://http.cat/200\">",
      ))
    }
    _ ->
      wisp.not_found()
      |> wisp.html_body(string_builder.from_string(
        "<img alt=\"Error 404: Not found\" src=\"https://http.cat/404\">",
      ))
  }
}
