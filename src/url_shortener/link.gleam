import gleam/crypto
import gleam/bit_array
import gleam/string
import gleam/list
import glanoid

pub fn random_back_half_from_nanoid(length: Int) -> String {
  let assert Ok(nanoid) =
    glanoid.make_generator(
      "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_",
    )
  nanoid(length)
}

pub fn random_back_half_from_crypto(length: Int) -> String {
  crypto.strong_random_bytes(length)
  |> bit_array.base64_url_encode(False)
  |> string.slice(0, length)
}

pub fn random_back_half_from_random_list(length: Int) -> String {
  // int.power(string.length(characters), int.to_float(length))
  // |> result.unwrap(0.0)
  // |> float.round()
  // |> int.random()

  let characters =
    string.to_graphemes(
      "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_",
    )
  generate_random_string(length, characters, 0, "")
}

pub fn generate_random_string(
  length: Int,
  characters: List(String),
  index: Int,
  string_so_far: String,
) -> String {
  case index {
    l if l >= length -> string_so_far
    _ -> {
      let assert Ok(new_char) =
        characters
        |> list.shuffle
        |> list.first()
      generate_random_string(
        length,
        characters,
        index + 1,
        string.append(string_so_far, new_char),
      )
    }
  }
}
