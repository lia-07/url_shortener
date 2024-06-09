import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/io
import gleam/json.{array, bool, int, null, object, string}
import gleam/option.{type Option, Some}
import gleam/result
import gleam/string
import gleam/uri
import sqlight
import url_shortener/error.{type AppError}
import url_shortener/web.{json_response}
import wisp.{type Request, type Response}

pub type Link {
  Link(back_half: String, original_url: String, hits: Int, created: String)
}

fn link_decoder() -> dynamic.Decoder(Link) {
  dynamic.decode4(
    Link,
    dynamic.element(0, dynamic.string),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, dynamic.int),
    dynamic.element(3, dynamic.string),
  )
}

pub fn get(back_half: String, req: Request, ctx: web.Context) {
  let stmt =
    "
  SELECT * FROM links
  WHERE back_half = (?1)
  "
  use rows <- result.then(
    sqlight.query(
      stmt,
      on: ctx.db,
      with: [sqlight.text(back_half)],
      expecting: link_decoder(),
    )
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

  case rows {
    [] -> {
      Error(error.NotFound)
    }
    [link, ..] -> {
      Ok(link)
    }
  }
}

pub fn shorten(req: Request, ctx) -> Response {
  let json =
    wisp.read_body_to_bitstring(req)
    |> result.unwrap(<<0>>)
    |> json.decode_bits(dynamic.dict(dynamic.string, dynamic.string))

  case json {
    Ok(data) -> handle_json(data, ctx)
    Error(err) -> error_json(err)
  }
}

pub fn info(req, ctx, link) {
  case get(link, req, ctx) {
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

pub fn hit(back_half, ctx: web.Context) {
  io.debug("hit fn is being run")
  let stmt =
    "
  UPDATE links 
  SET hits = hits + 1 
  WHERE back_half = (?1)
  returning back_half, original_url, hits, created
  "

  use rows <- result.try(
    sqlight.query(
      stmt,
      on: ctx.db,
      with: [sqlight.text(back_half)],
      expecting: link_decoder(),
    )
    |> result.map_error(fn(error) {
      case error.code, error.message {
        sqlight.ConstraintCheck, "CHECK constraint failed: empty_content" ->
          error.ContentRequired
        sqlight.ConstraintPrimarykey,
          "UNIQUE constraint failed: links.back_half"
        -> {
          io.debug("collison")
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

  case rows {
    [] -> {
      Error(error.NotFound)
    }
    [link, ..] -> {
      Ok(link.hits)
    }
  }
}

fn handle_json(data: Dict(String, String), ctx) {
  case dict.get(data, "url") {
    Ok(url) -> validate_and_process_url(url, ctx)
    Error(_) -> json_response(400, False, string("URL not specified"))
  }
}

// fn name_handler(name: String, ctx: Context) {
//   let stmt = "INSERT INTO names (name) VALUES (?1) RETURNING id"
//   use rows <- result.then(
//     sqlight.query(
//       stmt,
//       on: ctx.db,
//       with: [sqlight.text(name)],
//       expecting: dynamic.element(0, dynamic.int),
//     )
//     |> result.map_error(fn(error) {
//       case error.code, error.message {
//         sqlight.ConstraintCheck, "CHECK constraint failed: empty_content" ->
//           error.ContentRequired
//         _, _ -> {
//           io.debug(error.message)
//           error.BadRequest
//         }
//       }
//     }),
//   )

//   let assert [id] = rows
//   io.debug(id)
//   Ok(id)
// }

pub fn random_back_half(length: Int) -> String {
  crypto.strong_random_bytes(length)
  |> bit_array.base64_url_encode(False)
  |> string.slice(0, length)
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

fn validate_and_process_url(url, ctx) {
  case uri.parse(url) {
    Ok(uri.Uri(protocol, ..))
      if protocol == Some("http") || protocol == Some("https")
    -> {
      let link = insert_url(random_back_half(5), url, ctx)
      case link {
        Ok(Link(back_half, original_url, _, created)) ->
          json_response(
            code: 201,
            success: True,
            body: object([
              #("back_half", string(back_half)),
              #("original_url", string(original_url)),
              #("created", string(created)),
            ]),
          )
        Error(_) ->
          json_response(
            code: 500,
            success: False,
            body: string("An unexpected error occurred."),
          )
      }
    }
    _ -> {
      json_response(400, False, string("Invalid URL"))
    }
  }
}

fn insert_url(
  back_half,
  original_url,
  ctx: web.Context,
) -> Result(Link, AppError) {
  let stmt =
    "
    INSERT INTO links (back_half, original_url) 
    VALUES (?1, ?2) 
    RETURNING back_half, original_url, hits, created
    "
  use rows <- result.then(
    sqlight.query(
      stmt,
      on: ctx.db,
      with: [sqlight.text(back_half), sqlight.text(original_url)],
      expecting: link_decoder(),
    )
    |> result.map_error(fn(error) {
      case error.code, error.message {
        sqlight.ConstraintCheck, "CHECK constraint failed: empty_content" ->
          error.ContentRequired
        sqlight.ConstraintPrimarykey,
          "UNIQUE constraint failed: links.back_half"
        -> {
          io.debug("collison")
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

  let assert [link] = rows
  Ok(link)
}
