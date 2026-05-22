///|
/// Unsigned 128-bit helper used by the `SOFTFLOAT_FAST_INT64` port.
///
/// Fields are stored in SoftFloat's logical order: `hi` contains bits
/// 127..64 and `lo` contains bits 63..0.
priv struct UInt128 {
  hi : UInt64
  lo : UInt64
}

///|
/// Ports `struct uint64_extra` from `primitiveTypes.h`.
priv struct UInt64Extra {
  value : UInt64
  extra : UInt64
}

///|
fn uint128_zero() -> UInt128 {
  { hi: 0UL, lo: 0UL }
}

///|
fn uint128_is_zero(a : UInt128) -> Bool {
  (a.hi | a.lo) == 0UL
}

///|
/// Ports `softfloat_add128` from `s_add128.c`.
fn add128(a : UInt128, b : UInt128) -> UInt128 {
  let lo = a.lo + b.lo
  let carry = if lo < a.lo { 1UL } else { 0UL }
  { hi: a.hi + b.hi + carry, lo }
}

///|
/// Ports `softfloat_sub128` from `s_sub128.c`.
fn sub128(a : UInt128, b : UInt128) -> UInt128 {
  let borrow = if a.lo < b.lo { 1UL } else { 0UL }
  { hi: a.hi - b.hi - borrow, lo: a.lo - b.lo }
}

///|
/// Two's-complement negation equivalent to `softfloat_negX128M`.
fn neg128(a : UInt128) -> UInt128 {
  sub128(uint128_zero(), a)
}

///|
/// Ports `softfloat_shortShiftLeft128` from `s_shortShiftLeft128.c`.
fn short_shift_left128(a : UInt128, dist : Int) -> UInt128 {
  shift_left128_m(a, dist)
}

///|
/// Typed 128-bit equivalent of `softfloat_shiftLeft128M`.
fn shift_left128_m(a : UInt128, dist : Int) -> UInt128 {
  if dist <= 0 {
    a
  } else if dist < 64 {
    { hi: (a.hi << dist) | (a.lo >> (64 - dist)), lo: a.lo << dist }
  } else if dist < 128 {
    { hi: a.lo << (dist - 64), lo: 0UL }
  } else {
    uint128_zero()
  }
}

///|
/// Ports `softfloat_mul64To128` from `s_mul64To128.c`.
fn mul64_to_128(a : UInt64, b : UInt64) -> UInt128 {
  let a32 = a >> 32
  let a0 = a & 0xFFFFFFFFUL
  let b32 = b >> 32
  let b0 = b & 0xFFFFFFFFUL
  let lo0 = a0 * b0
  let mid1 = a32 * b0
  let mid = mid1 + a0 * b32
  let carry_mid = if mid < mid1 { 1UL << 32 } else { 0UL }
  let hi = a32 * b32 + carry_mid + (mid >> 32)
  let mid_shifted = mid << 32
  let lo = lo0 + mid_shifted
  let hi = if lo < mid_shifted { hi + 1UL } else { hi }
  { hi, lo }
}
