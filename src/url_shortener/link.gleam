import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/io
import gleam/json.{int, object, string}
import gleam/option.{type Option, None, Some}
import gleam/regex
import gleam/result
import gleam/string
import gleam/uri
import sqlight
import url_shortener/error.{type AppError}
import url_shortener/web.{json_response}
import wisp.{type Request, type Response}

// type containing the link constructor. matches the database model.
pub type Link {
  Link(back_half: String, original_url: String, hits: Int, created: String)
}

// allows murky data from the database to be transformed into a type-safe 
// (cont.) gleam dict 
fn link_decoder() -> dynamic.Decoder(Link) {
  dynamic.decode4(
    Link,
    dynamic.element(0, dynamic.string),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, dynamic.int),
    dynamic.element(3, dynamic.string),
  )
}

// return all information on a link with the given back_half
pub fn get(back_half: String, ctx: web.Context) {
  let stmt =
    "
  SELECT * FROM links
  WHERE back_half = (?1)
  "

  // query the database with the above sql statment
  use rows <- result.then(
    sqlight.query(
      stmt,
      on: ctx.db,
      with: [sqlight.text(back_half)],
      expecting: link_decoder(),
    )
    // if there's an error, return an error
    |> result.map_error(fn(error) {
      case error.code, error.message {
        sqlight.ConstraintCheck, "CHECK constraint failed: empty_content" ->
          error.ContentRequired
        _, _ -> {
          error.BadRequest
        }
      }
    }),
  )

  // if there are no results, return an error. if there is, return the 
  // (cont.) first one 
  case rows {
    [] -> {
      Error(error.NotFound)
    }
    [link, ..] -> {
      Ok(link)
    }
  }
}

fn parse_json(req: Request) -> Result(Dict(String, String), AppError) {
  let json =
    wisp.read_body_to_bitstring(req)
    |> result.unwrap(<<0>>)
    |> json.decode_bits(dynamic.dict(dynamic.string, dynamic.string))

  case json {
    Ok(j) -> Ok(j)
    Error(e) -> Error(error.JsonError(e))
  }
}

fn get_url(json: Dict(String, String)) {
  case dict.get(json, "url") {
    Ok(url) -> {
      case uri.parse(url) {
        Ok(uri.Uri(protocol, ..))
          if protocol == Some("http") || protocol == Some("https")
        -> Ok(url)
        _ -> Error(error.InvalidUrl)
      }
    }
    Error(_) -> Error(error.InvalidUrl)
  }
}

fn get_requested_back_half(
  json: Dict(String, String),
) -> Result(Option(String), AppError) {
  case dict.get(json, "back_half") {
    Ok(back_half) -> {
      let assert Ok(r) = regex.from_string("^[A-Za-z0-9_-]{3,32}$")
      case regex.check(r, back_half) {
        True -> Ok(Some(back_half))
        False -> Error(error.InvalidBackHalf)
      }
    }
    Error(_) -> Ok(None)
  }
}

// shorten a link
pub fn shorten(req: Request, ctx) -> Response {
  // attempt to decode the request body as json
  let link = {
    use json <- result.try(parse_json(req))

    use url <- result.try(get_url(json))

    case get_requested_back_half(json) {
      Ok(None) -> insert_link(url, ctx, None, Some(4))
      Ok(Some(back_half)) -> insert_link(url, ctx, Some(back_half), None)
      Error(_) -> Error(error.InvalidBackHalf)
    }
  }

  case link {
    Ok(Link(back_half, original_url, _, created)) -> {
      json_response(
        code: 201,
        success: True,
        body: object([
          #("back_half", string(back_half)),
          #("original_url", string(original_url)),
          #("created", string(created)),
        ]),
      )
    }
    Error(err) -> {
      case err {
        // if the error was caused by an invalid type
        error.JsonError(json.UnexpectedFormat([dynamic.DecodeError(e, f, _)])) ->
          json_response(
            400,
            False,
            string(
              "Invalid data type (expected " <> e <> ", found " <> f <> ")",
            ),
          )
        error.JsonError(_) ->
          json_response(code: 400, success: False, body: string("Invalid JSON"))
        error.Conflict ->
          json_response(
            409,
            False,
            string("Requested back half already in use"),
          )
        error.InvalidUrl ->
          json_response(code: 400, success: False, body: string("Invalid URL"))
        error.InvalidBackHalf ->
          json_response(
            code: 400,
            success: False,
            body: string(
              "Requested back half invalid: must be between 3 and 32 characters long and only contain characters A-Z, a-z, 0-9, '-', and '_'",
            ),
          )

        _ ->
          json_response(
            code: 500,
            success: False,
            body: string("An unexpected error"),
          )
      }
    }
  }
}

// get info about a given link. most work is done in the get() function
pub fn info(ctx, link) {
  case get(link, ctx) {
    // if a link was found in the database, respond with all info on the link
    Ok(Link(back_half, original_url, hits, created)) -> {
      json_response(
        code: 200,
        success: True,
        body: object([
          #("back_half", string(back_half)),
          #("original_url", string(original_url)),
          #("hits", int(hits)),
          #("created", string(created)),
        ]),
      )
    }
    // if no link was found, respond with an error
    Error(err) ->
      case err {
        error.NotFound -> {
          json_response(
            code: 404,
            success: False,
            body: string("Specified link not found"),
          )
        }
        _ -> {
          json_response(
            code: 500,
            success: False,
            body: string("An unexpected error occured"),
          )
        }
      }
  }
}

// increment the hit value of a link with the given back_half
pub fn hit(back_half, ctx: web.Context) {
  let stmt =
    "
  UPDATE links 
  SET hits = hits + 1 
  WHERE back_half = (?1)
  returning back_half, original_url, hits, created
  "

  // query the database with the above statement
  use rows <- result.try(
    sqlight.query(
      stmt,
      on: ctx.db,
      with: [sqlight.text(back_half)],
      expecting: link_decoder(),
    )
    // if there's an error, return an error
    |> result.map_error(fn(error) {
      case error.code, error.message {
        sqlight.ConstraintCheck, "CHECK constraint failed: empty_content" ->
          error.ContentRequired
        sqlight.ConstraintPrimarykey,
          "UNIQUE constraint failed: links.back_half"
        -> {
          error.SqlightError(error)
        }
        _, _ -> {
          io.debug(error.code)
          io.debug(error.message)
          error.BadRequest
        }
      }
    }),
  )

  // if no link was found, return an error. otherwise return the new amount
  // (cont.) of hits
  case rows {
    [] -> {
      Error(error.NotFound)
    }
    [link, ..] -> {
      Ok(link.hits)
    }
  }
}

// generate a random back half of a given length. uses base64
pub fn random_back_half(length: Int) -> String {
  case length {
    4 -> "help"
    5 -> "sigma"
    _ ->
      crypto.strong_random_bytes(length)
      |> bit_array.base64_url_encode(False)
      |> string.slice(0, length)
  }
}

// insert a url to the database
fn insert_link(
  original_url,
  ctx: web.Context,
  requested_back_half: Option(String),
  i: Option(Int),
) -> Result(Link, AppError) {
  let back_half =
    requested_back_half
    |> option.unwrap(random_back_half(option.unwrap(i, 4)))

  let stmt =
    "
    INSERT INTO links (back_half, original_url) 
    VALUES (?1, ?2) 
    RETURNING back_half, original_url, hits, created
    "

  // query db with above statement
  let rows =
    sqlight.query(
      stmt,
      on: ctx.db,
      with: [sqlight.text(back_half), sqlight.text(original_url)],
      expecting: link_decoder(),
    )

  case rows {
    // if the query was successful, return the newly shortened link
    Ok(row) -> {
      let assert [link] = row
      Ok(link)
    }
    // if the query failed, return an error or try again with a 1 digit longer
    // (cont.) random back half
    Error(err) -> {
      case err.code, err.message {
        // if a collision happened (i.e. tried to insert with the same 
        // (cont.) back half)
        sqlight.ConstraintPrimarykey,
          "UNIQUE constraint failed: links.back_half"
        -> {
          case option.is_some(i) {
            True -> {
              wisp.log_warning("Collision: \"" <> back_half <> "\"")

              insert_link(
                original_url,
                ctx,
                None,
                Some(option.unwrap(i, 4) + 1),
              )
            }
            False -> Error(error.Conflict)
          }
        }
        // catch all, return a bad request error and print the details
        _, _ -> {
          wisp.log_error(err.message)
          io.debug(err.code)
          Error(
            error.SqlightError(sqlight.SqlightError(
              err.code,
              err.message,
              err.offset,
            )),
          )
        }
      }
    }
  }
}
