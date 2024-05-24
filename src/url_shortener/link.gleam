import gleam/crypto
import gleam/dict
import gleam/dynamic
import gleam/io
import gleam/bit_array
import gleam/string
import gleam/json.{array, bool, int, null, object, string}
import wisp.{type Request, type Response}

pub fn random_back_half(length: Int) -> String {
  crypto.strong_random_bytes(length)
  |> bit_array.base64_url_encode(False)
  |> string.slice(0, length)
}

pub fn shorten(req: Request, ctx) -> Response {
  use json <- wisp.require_json(req)
  io.debug(json)
  let data =
    json
    |> dynamic.dict(dynamic.string, dynamic.string)

  case data {
    Ok(d) -> {
      case dict.get(d, "url") {
        Ok(u) -> io.debug(u)
        _ -> io.debug("help")
      }
    }
    _ -> io.debug("help")
  }

  // not implemented 
  wisp.response(501)
  |> wisp.json_body(
    object([
      #("success", bool(False)),
      #("error", string("Shorten endpoint not yet implemented")),
    ])
    |> json.to_string_builder(),
  )
}

pub fn info(req: Request, ctx) -> Response {
  // not implemented 
  wisp.response(501)
  |> wisp.json_body(
    object([
      #("success", bool(False)),
      #("error", string("Info endpoint not yet implemented")),
    ])
    |> json.to_string_builder(),
  )
}
