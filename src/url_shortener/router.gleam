import gleam/string_builder
import gleam/result
import gleam/io
import gleam/int
import gleam/dynamic
import wisp.{type Request, type Response}
import sqlight
import url_shortener/error
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
      let id = result.unwrap(name_handler(name, ctx), -1)
      wisp.ok()
      |> wisp.html_body(string_builder.from_string(
        "<h1>Hi "
        <> name
        <> "!</h1><p>Here is a present: &#127873;</p><p>Your id is "
        <> int.to_string(id)
        <> "</p> <img alt=\"200: Ok\" src=\"https://http.cat/200\">",
      ))
    }
    _ ->
      wisp.not_found()
      |> wisp.html_body(string_builder.from_string(
        "<img alt=\"Error 404: Not found\" src=\"https://http.cat/404\">",
      ))
  }
}

fn name_handler(name: String, ctx: Context) {
  let stmt = "INSERT INTO names (name) VALUES (?1) RETURNING id"
  use rows <- result.then(
    sqlight.query(
      stmt,
      on: ctx.db,
      with: [sqlight.text(name)],
      expecting: dynamic.element(0, dynamic.int),
    )
    |> result.map_error(fn(error) {
      case error.code, error.message {
        sqlight.ConstraintCheck, "CHECK constraint failed: empty_content" ->
          error.ContentRequired
        _, _ -> {
          io.debug(error.message)
          error.BadRequest
        }
      }
    }),
  )

  let assert [id] = rows
  io.debug(id)
  Ok(id)
}
