import gleam/crypto
import gleam/dict.{type Dict}
import gleam/result
import gleam/dynamic
import gleam/option.{type Option, Some}
import gleam/uri
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
    Ok(data) -> handle_json(data)
    Error(err) -> error_json(err)
  }
}

pub fn info(req: Request, ctx) -> Response {
  json_response(501, False, string("Info endpoint is not yet implemented"))
}

fn handle_json(data: Dict(String, String)) {
  case dict.get(data, "url") {
    Ok(url) -> validate_and_process_url(url)
    Error(_) -> json_response(400, False, string("URL not specified"))
  }
}

fn error_json(err) {
  case err {
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

fn validate_and_process_url(url) {
  case uri.parse(url) {
    Ok(uri.Uri(protocol, ..))
      if protocol == Some("http") || protocol == Some("https")
    -> {
      json_response(
        201,
        True,
        object([
          #("back_half", string(random_back_half(5))),
          #("original_url", string(url)),
        ]),
      )
    }
    _ -> {
      json_response(400, False, string("Invalid URL"))
    }
  }
}
