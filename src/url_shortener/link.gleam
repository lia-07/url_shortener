import gleam/crypto
import gleam/bit_array
import gleam/string

pub fn random_back_half(length: Int) -> String {
  crypto.strong_random_bytes(length)
  |> bit_array.base64_url_encode(False)
  |> string.slice(0, length)
}
