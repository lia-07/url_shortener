import gleam/http.{Get, Post}
import gleam/io
import gleam/json.{array, bool, int, null, object, string}
import gleam/otp/task
import gleam/string
import url_shortener/error.{type AppError}
import url_shortener/link.{type Link}
import url_shortener/web.{type Context, json_response}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["api", ..version] -> api_version_handler(req, ctx, version)
    back_half -> shortened_link_handler(string.concat(back_half), req, ctx)
  }
}

fn shortened_link_handler(back_half, req, ctx) {
  case link.get(back_half, req, ctx) {
    Ok(match) -> {
      let _ = link.hit(match.back_half, ctx)
      wisp.moved_permanently(match.original_url)
    }
    Error(_) -> wisp.not_found()
  }
}

fn api_version_handler(req, ctx, version) {
  case version {
    ["v1", ..endpoint] -> v1_api_handler(req, ctx, endpoint)
    _ ->
      json_response(
        code: 404,
        success: False,
        body: string("The API version specified does not exist"),
      )
  }
}

fn v1_api_handler(req: Request, ctx, endpoint) {
  case endpoint {
    ["link", ..rest] -> v1_api_link_handler(req, ctx, rest)
    _ -> {
      json_response(
        code: 404,
        success: False,
        body: string("The endpoint specified does not exist"),
      )
    }
  }
}

fn v1_api_link_handler(req: Request, ctx, rest) {
  case rest {
    [] -> {
      case req.method {
        Post -> link.shorten(req, ctx)
        _ -> wisp.method_not_allowed([Post])
      }
    }
    link -> {
      case req.method {
        Get -> link.info(req, ctx, string.concat(link))
        _ -> wisp.method_not_allowed([Get])
      }
    }
  }
}
