import gleam/http.{Get, Post}
import gleam/json.{string}
import gleam/string
import url_shortener/link
import url_shortener/web.{type Context, json_response}
import wisp.{type Request, type Response}

// main router function. maps paths to functions that return responses
pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    // if it's an api route, go to the api handler(s)
    ["api", ..version] -> api_version_handler(req, ctx, version)
    // catch all, this goes to the shorten link handler. this could be used for
    // (cont.) a 404 page if this wasn't a url shortener
    back_half -> shortened_link_handler(string.concat(back_half), ctx)
  }
}

// try to redirect to the original url of a specified link. if it doesn't exist,
// (cont.) respond with 404
fn shortened_link_handler(back_half, ctx) {
  case link.get(back_half, ctx) {
    Ok(match) -> {
      let _ = link.hit(match.back_half, ctx)
      wisp.moved_permanently(match.original_url)
    }
    Error(_) -> wisp.not_found()
  }
}

// currently there is only v1 for the api, but in the future there might be more
fn api_version_handler(req, ctx, version) {
  case version {
    ["v1", ..endpoint] -> v1_api_handler(req, ctx, endpoint)
    // if an invalid api version is specified, respond with 404
    _ ->
      json_response(
        code: 404,
        success: False,
        body: string("The API version specified does not exist"),
      )
  }
}

// currently there is only a link endpoint
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

// decide whether they were accessing the info endpoint or the create endpoint,
// (cont.) and activate the corresponding function
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
        Get -> link.info(ctx, string.concat(link))
        _ -> wisp.method_not_allowed([Get])
      }
    }
  }
}
