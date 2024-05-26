import gleam/crypto
import gleam/dict
import gleam/dynamic
import gleam/io
import gleam/bit_array
import gleam/string
import gleam/json.{array, bool, int, null, object, string}
import wisp.{type Request, type Response}
import url_shortener/web.{json_response}

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

  json_response(501, False, string("Create endpoint is not yet implemented"))
}

pub fn info(req: Request, ctx) -> Response {
  json_response(501, False, string("Info endpoint is not yet implemented"))
}
