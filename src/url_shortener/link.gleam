import glanoid

pub fn random_back_half(length: Int) -> String {
  let assert Ok(nanoid) =
    glanoid.make_generator(
      "_-!?@#$%&0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
    )
  nanoid(length)
}
