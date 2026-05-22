///|
/// Ports `signF16UI` from SoftFloat `internals.h`.
fn sign_f16_ui(bits : UInt16) -> Bool {
  bits >> 15 != 0
}

///|
/// Ports `expF16UI` from SoftFloat `internals.h`.
fn exp_f16_ui(bits : UInt16) -> Int {
  ((bits >> 10) & 0x1F).to_int()
}

///|
/// Ports `fracF16UI` from SoftFloat `internals.h`.
fn frac_f16_ui(bits : UInt16) -> UInt16 {
  bits & 0x03FF
}

///|
/// Ports `packToF16UI` from SoftFloat `internals.h`.
fn pack_to_f16_ui(sign : Bool, exp : Int, sig : UInt16) -> UInt16 {
  let sign_bits : UInt16 = if sign { 1 << 15 } else { 0 }
  sign_bits + (exp.to_uint16() << 10) + sig
}

///|
/// Ports `isNaNF16UI` from SoftFloat `internals.h`.
fn is_nan_f16_ui(bits : UInt16) -> Bool {
  (bits & 0x7C00) == 0x7C00 && (bits & 0x03FF) != 0
}

///|
/// Ports `signBF16UI` from SoftFloat `internals.h`.
fn sign_bf16_ui(bits : UInt16) -> Bool {
  bits >> 15 != 0
}

///|
/// Ports `expBF16UI` from SoftFloat `internals.h`.
fn exp_bf16_ui(bits : UInt16) -> Int {
  ((bits >> 7) & 0xFF).to_int()
}

///|
/// Ports `fracBF16UI` from SoftFloat `internals.h`.
fn frac_bf16_ui(bits : UInt16) -> UInt16 {
  bits & 0x007F
}

///|
/// Ports `packToBF16UI` from SoftFloat `internals.h`.
fn pack_to_bf16_ui(sign : Bool, exp : Int, sig : UInt16) -> UInt16 {
  let sign_bits : UInt16 = if sign { 1 << 15 } else { 0 }
  sign_bits + (exp.to_uint16() << 7) + sig
}

///|
/// Ports `isNaNBF16UI` from SoftFloat `internals.h`.
fn is_nan_bf16_ui(bits : UInt16) -> Bool {
  (bits & 0x7F80) == 0x7F80 && (bits & 0x007F) != 0
}

///|
/// Ports `signF32UI` from SoftFloat `internals.h`.
fn sign_f32_ui(bits : UInt) -> Bool {
  bits >> 31 != 0U
}

///|
/// Ports `expF32UI` from SoftFloat `internals.h`.
fn exp_f32_ui(bits : UInt) -> Int {
  ((bits >> 23) & 0xFFU).reinterpret_as_int()
}

///|
/// Ports `fracF32UI` from SoftFloat `internals.h`.
fn frac_f32_ui(bits : UInt) -> UInt {
  bits & 0x007FFFFFU
}

///|
/// Ports `packToF32UI` from SoftFloat `internals.h`.
fn pack_to_f32_ui(sign : Bool, exp : Int, sig : UInt) -> UInt {
  let sign_bits = if sign { 1U << 31 } else { 0U }
  sign_bits + (exp.reinterpret_as_uint() << 23) + sig
}

///|
/// Ports `isNaNF32UI` from SoftFloat `internals.h`.
fn is_nan_f32_ui(bits : UInt) -> Bool {
  (bits & 0x7F800000U) == 0x7F800000U && (bits & 0x007FFFFFU) != 0U
}

///|
/// Ports `signF64UI` from SoftFloat `internals.h`.
fn sign_f64_ui(bits : UInt64) -> Bool {
  bits >> 63 != 0UL
}

///|
/// Ports `expF64UI` from SoftFloat `internals.h`.
fn exp_f64_ui(bits : UInt64) -> Int {
  ((bits >> 52) & 0x7FFUL).to_int()
}

///|
/// Ports `fracF64UI` from SoftFloat `internals.h`.
fn frac_f64_ui(bits : UInt64) -> UInt64 {
  bits & 0x000FFFFFFFFFFFFFUL
}

///|
/// Ports `packToF64UI` from SoftFloat `internals.h`.
fn pack_to_f64_ui(sign : Bool, exp : Int, sig : UInt64) -> UInt64 {
  let sign_bits = if sign { 1UL << 63 } else { 0UL }
  sign_bits + (exp.to_uint64() << 52) + sig
}

///|
/// Ports `isNaNF64UI` from SoftFloat `internals.h`.
fn is_nan_f64_ui(bits : UInt64) -> Bool {
  (bits & 0x7FF0000000000000UL) == 0x7FF0000000000000UL &&
  (bits & 0x000FFFFFFFFFFFFFUL) != 0UL
}
