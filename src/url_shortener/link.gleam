import gleam/crypto
import gleam/dict
import gleam/result
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
  let json =
    wisp.read_body_to_bitstring(req)
    |> result.unwrap(<<0>>)
    |> json.decode_bits(dynamic.dict(dynamic.string, dynamic.string))

  case json {
    Ok(j) -> {
      case dict.get(j, "url") {
        Ok(u) ->
          json_response(
            201,
            True,
            object([
              #("back_half", string(random_back_half(5))),
              #("original_url", string(u)),
            ]),
          )
        Error(_) -> json_response(400, False, string("URL not specified"))
      }
    }
    Error(x) ->
      case x {
        json.UnexpectedFormat([dynamic.DecodeError(e, f, _)]) ->
          json_response(
            400,
            False,
            string(
              "Invalid data type (expected "
              <> string.lowercase(e)
              <> ", found "
              <> string.lowercase(f)
              <> ")",
            ),
          )

        _ -> json_response(400, False, string("Invalid JSON"))
      }
  }
}

pub fn info(req: Request, ctx) -> Response {
  json_response(501, False, string("Info endpoint is not yet implemented"))
}
