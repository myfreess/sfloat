///|
/// IEEE 754 binary16 bit wrapper used by SoftFloat operations.
///
/// The stored value is the raw 16-bit payload. Public construction is through
/// `F16::from_bits`; operations never reinterpret it through host floats.
/// All bit patterns are accepted, including signed zeros, subnormals,
/// infinities, quiet NaNs, and signaling NaNs.
pub struct F16(UInt16)

///|
/// Creates an `F16` from its raw IEEE 754 binary16 bits.
///
/// The bits are stored exactly as provided. NaN payloads are not quieted or
/// canonicalized here, and no SoftFloat exception flags are raised.
pub fn F16::from_bits(bits : UInt16) -> F16 {
  F16(bits)
}

///|
/// Returns the raw IEEE 754 binary16 bits stored in this value.
///
/// For values created with `F16::from_bits`, this is an exact round trip even
/// for NaNs and signed zeros.
pub fn F16::to_bits(self : F16) -> UInt16 {
  self.0
}

///|
/// IEEE 754 bfloat16 bit wrapper used by SoftFloat conversion operations.
///
/// The stored value is the raw 16-bit payload. v1 includes BF16 conversion and
/// NaN classification, but no standalone BF16 arithmetic. All BF16 bit
/// patterns are representable by this wrapper.
pub struct BF16(UInt16)

///|
/// Creates a `BF16` from its raw bfloat16 bits.
///
/// Construction is purely bit-level: NaNs, infinities, subnormals, and signed
/// zeros are preserved without raising flags.
pub fn BF16::from_bits(bits : UInt16) -> BF16 {
  BF16(bits)
}

///|
/// Returns the raw bfloat16 bits stored in this value.
///
/// This is an exact round trip for every value created by `BF16::from_bits`.
pub fn BF16::to_bits(self : BF16) -> UInt16 {
  self.0
}

///|
/// IEEE 754 binary32 bit wrapper used by SoftFloat operations.
///
/// The stored value is the raw 32-bit payload. Native `Float` bridges only
/// reinterpret bits and are not used to compute SoftFloat results. All
/// binary32 encodings are accepted, including noncanonical NaN payloads.
pub struct F32(UInt)

///|
/// Creates an `F32` from its raw IEEE 754 binary32 bits.
///
/// The payload is stored unchanged. This constructor does not raise flags and
/// does not canonicalize signaling NaNs.
pub fn F32::from_bits(bits : UInt) -> F32 {
  F32(bits)
}

///|
/// Returns the raw IEEE 754 binary32 bits stored in this value.
///
/// The result preserves signs of zero and NaN payload bits exactly.
pub fn F32::to_bits(self : F32) -> UInt {
  self.0
}

///|
/// Reinterprets a native `Float` bit pattern as an `F32`.
///
/// This helper performs no arithmetic and raises no SoftFloat flags. Host NaNs
/// are taken as their raw in-memory `Float` bit pattern; no SoftFloat NaN
/// propagation rules are applied.
pub fn F32::from_float_bits(value : Float) -> F32 {
  F32(value.reinterpret_as_uint())
}

///|
/// Reinterprets this `F32` bit pattern as a native `Float`.
///
/// This helper performs no arithmetic and raises no SoftFloat flags. The host
/// runtime receives the raw bits, including NaN payloads and signed zeros.
pub fn F32::to_float_bits(self : F32) -> Float {
  Float::reinterpret_from_uint(self.0)
}

///|
/// IEEE 754 binary64 bit wrapper used by SoftFloat operations.
///
/// The stored value is the raw 64-bit payload. Native `Double` bridges only
/// reinterpret bits and are not used to compute SoftFloat results. Every
/// binary64 encoding is representable by this wrapper.
pub struct F64(UInt64)

///|
/// Creates an `F64` from its raw IEEE 754 binary64 bits.
///
/// The bits are stored as-is. This is safe for infinities, subnormals, signed
/// zeros, and both quiet and signaling NaNs; no flags are raised.
pub fn F64::from_bits(bits : UInt64) -> F64 {
  F64(bits)
}

///|
/// Returns the raw IEEE 754 binary64 bits stored in this value.
///
/// This is an exact round trip for all values created by `F64::from_bits`.
pub fn F64::to_bits(self : F64) -> UInt64 {
  self.0
}

///|
/// Reinterprets a native `Double` bit pattern as an `F64`.
///
/// This helper performs no arithmetic and raises no SoftFloat flags. Host NaNs
/// are captured by bit pattern, without SoftFloat canonicalization.
pub fn F64::from_double_bits(value : Double) -> F64 {
  F64(value.reinterpret_as_uint64())
}

///|
/// Reinterprets this `F64` bit pattern as a native `Double`.
///
/// This helper performs no arithmetic and raises no SoftFloat flags. The host
/// runtime receives exactly the stored binary64 bits.
pub fn F64::to_double_bits(self : F64) -> Double {
  self.0.reinterpret_as_double()
}

///|
/// Result of a SoftFloat operation paired with the updated explicit context.
///
/// Operations that can raise IEEE flags return this shape instead of mutating
/// global SoftFloat state. `value` is the operation result, while `context`
/// contains the original context with any newly raised flags accumulated.
/// Exact operations usually return the input context unchanged.
pub(all) struct SoftResult[T] {
  value : T
  context : Context
}
