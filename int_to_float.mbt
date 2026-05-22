///|
fn abs_i32_bits(a : Int) -> (Bool, UInt) {
  let sign = a < 0
  let bits = a.reinterpret_as_uint()
  (sign, if sign { 0U - bits } else { bits })
}

///|
fn abs_i64_bits(a : Int64) -> (Bool, UInt64) {
  let sign = a < 0L
  let bits = a.reinterpret_as_uint64()
  (sign, if sign { 0UL - bits } else { bits })
}

///|
fn int32_magnitude_to_f16(
  context : Context,
  sign : Bool,
  abs_a : UInt,
) -> SoftResult[F16] {
  let mut shift_dist = count_leading_zeros32(abs_a) - 21
  if shift_dist >= 0 {
    {
      value: F16::from_bits(
        if abs_a == 0U {
          0
        } else {
          pack_to_f16_ui(
            sign,
            0x18 - shift_dist,
            (abs_a << shift_dist).to_uint16(),
          )
        },
      ),
      context,
    }
  } else {
    shift_dist = shift_dist + 4
    let sig = if shift_dist < 0 {
      shift_right_jam32(abs_a, -shift_dist)
    } else {
      abs_a << shift_dist
    }
    round_pack_to_f16(context, sign, 0x1C - shift_dist, sig)
  }
}

///|
fn int64_magnitude_to_f16(
  context : Context,
  sign : Bool,
  abs_a : UInt64,
) -> SoftResult[F16] {
  let mut shift_dist = count_leading_zeros64(abs_a) - 53
  if shift_dist >= 0 {
    {
      value: F16::from_bits(
        if abs_a == 0UL {
          0
        } else {
          pack_to_f16_ui(
            sign,
            0x18 - shift_dist,
            (abs_a << shift_dist).to_uint16(),
          )
        },
      ),
      context,
    }
  } else {
    shift_dist = shift_dist + 4
    let sig = if shift_dist < 0 {
      short_shift_right_jam64(abs_a, -shift_dist).to_uint()
    } else {
      (abs_a << shift_dist).to_uint()
    }
    round_pack_to_f16(context, sign, 0x1C - shift_dist, sig)
  }
}

///|
/// Converts an unsigned 32-bit integer to F16.
///
/// Zero converts exactly to positive zero. Values that fit exactly in binary16
/// leave the context unchanged; values that need rounding may raise `Inexact`.
/// Large inputs may overflow to infinity or the largest finite F16 according
/// to `context.rounding`, raising `Overflow | Inexact`. This conversion never
/// raises `Invalid`.
pub fn ui32_to_f16(context : Context, a : UInt) -> SoftResult[F16] {
  int32_magnitude_to_f16(context, false, a)
}

///|
/// Converts a signed 32-bit integer to F16.
///
/// Integer zero produces positive zero. The most-negative `Int` is handled
/// without taking a host `abs`. Nonrepresentable magnitudes round according to
/// the context and may raise `Inexact` or `Overflow | Inexact`, but never
/// `Invalid`.
pub fn i32_to_f16(context : Context, a : Int) -> SoftResult[F16] {
  let (sign, abs_a) = abs_i32_bits(a)
  int32_magnitude_to_f16(context, sign, abs_a)
}

///|
/// Converts an unsigned 64-bit integer to F16.
///
/// Zero is exact. Any nonzero value is rounded according to `context.rounding`;
/// results outside the finite F16 range raise `Overflow | Inexact` and return
/// either signed infinity or the maximum finite value as SoftFloat specifies.
pub fn ui64_to_f16(context : Context, a : UInt64) -> SoftResult[F16] {
  int64_magnitude_to_f16(context, false, a)
}

///|
/// Converts a signed 64-bit integer to F16.
///
/// The sign is preserved for nonzero values, including the minimum `Int64`.
/// Values too large for binary16 raise `Overflow | Inexact`; other inexact
/// conversions raise `Inexact`. No NaN or invalid conversion is possible from
/// an integer source.
pub fn i64_to_f16(context : Context, a : Int64) -> SoftResult[F16] {
  let (sign, abs_a) = abs_i64_bits(a)
  int64_magnitude_to_f16(context, sign, abs_a)
}

///|
/// Converts an unsigned 32-bit integer to F32.
///
/// Zero converts exactly to positive zero. Values with more precision than
/// binary32 can store are rounded according to `context.rounding` and may raise
/// `Inexact`; the UInt32 range never overflows F32.
pub fn ui32_to_f32(context : Context, a : UInt) -> SoftResult[F32] {
  if a == 0U {
    { value: F32::from_bits(0U), context }
  } else if (a & 0x80000000U) != 0U {
    round_pack_to_f32(context, false, 0x9D, (a >> 1) | (a & 1U))
  } else {
    norm_round_pack_to_f32(context, false, 0x9C, a)
  }
}

///|
/// Converts a signed 32-bit integer to F32.
///
/// The minimum `Int` is converted by bit magnitude rather than host absolute
/// value. All results are finite; only precision loss can raise `Inexact`.
pub fn i32_to_f32(context : Context, a : Int) -> SoftResult[F32] {
  let sign = a < 0
  let bits = a.reinterpret_as_uint()
  if (bits & 0x7FFFFFFFU) == 0U {
    {
      value: F32::from_bits(
        if sign {
          pack_to_f32_ui(true, 0x9E, 0U)
        } else {
          0U
        },
      ),
      context,
    }
  } else {
    let (_, abs_a) = abs_i32_bits(a)
    norm_round_pack_to_f32(context, sign, 0x9C, abs_a)
  }
}

///|
/// Converts an unsigned 64-bit integer to F32 with SoftFloat rounding.
///
/// Zero is exact. Large integer magnitudes remain finite in F32, but most
/// values above the binary32 precision range raise `Inexact` after rounding.
pub fn ui64_to_f32(context : Context, a : UInt64) -> SoftResult[F32] {
  let mut shift_dist = count_leading_zeros64(a) - 40
  if shift_dist >= 0 {
    {
      value: F32::from_bits(
        if a == 0UL {
          0U
        } else {
          pack_to_f32_ui(false, 0x95 - shift_dist, (a << shift_dist).to_uint())
        },
      ),
      context,
    }
  } else {
    shift_dist = shift_dist + 7
    let sig = if shift_dist < 0 {
      short_shift_right_jam64(a, -shift_dist).to_uint()
    } else {
      (a << shift_dist).to_uint()
    }
    round_pack_to_f32(context, false, 0x9C - shift_dist, sig)
  }
}

///|
/// Converts a signed 64-bit integer to F32 with SoftFloat rounding.
///
/// The sign is preserved for nonzero inputs, including the minimum `Int64`.
/// The result never overflows F32; precision loss is reported with `Inexact`.
pub fn i64_to_f32(context : Context, a : Int64) -> SoftResult[F32] {
  let (sign, abs_a) = abs_i64_bits(a)
  let mut shift_dist = count_leading_zeros64(abs_a) - 40
  if shift_dist >= 0 {
    {
      value: F32::from_bits(
        if abs_a == 0UL {
          0U
        } else {
          pack_to_f32_ui(
            sign,
            0x95 - shift_dist,
            (abs_a << shift_dist).to_uint(),
          )
        },
      ),
      context,
    }
  } else {
    shift_dist = shift_dist + 7
    let sig = if shift_dist < 0 {
      short_shift_right_jam64(abs_a, -shift_dist).to_uint()
    } else {
      (abs_a << shift_dist).to_uint()
    }
    round_pack_to_f32(context, sign, 0x9C - shift_dist, sig)
  }
}

///|
/// Converts an unsigned 32-bit integer to F64 exactly.
///
/// Every UInt32 value is exactly representable in binary64, so the returned
/// context is unchanged.
pub fn ui32_to_f64(context : Context, a : UInt) -> SoftResult[F64] {
  if a == 0U {
    { value: F64::from_bits(0UL), context }
  } else {
    let shift_dist = count_leading_zeros32(a) + 21
    {
      value: F64::from_bits(
        pack_to_f64_ui(false, 0x432 - shift_dist, a.to_uint64() << shift_dist),
      ),
      context,
    }
  }
}

///|
/// Converts a signed 32-bit integer to F64 exactly.
///
/// Every Int32 value, including the minimum value, is exactly representable in
/// binary64. The result is finite and raises no flags.
pub fn i32_to_f64(context : Context, a : Int) -> SoftResult[F64] {
  if a == 0 {
    { value: F64::from_bits(0UL), context }
  } else {
    let (sign, abs_a) = abs_i32_bits(a)
    let shift_dist = count_leading_zeros32(abs_a) + 21
    {
      value: F64::from_bits(
        pack_to_f64_ui(
          sign,
          0x432 - shift_dist,
          abs_a.to_uint64() << shift_dist,
        ),
      ),
      context,
    }
  }
}

///|
/// Converts an unsigned 64-bit integer to F64 with SoftFloat rounding.
///
/// Values up to the binary64 precision limit are exact. Larger values are
/// rounded according to `context.rounding` and may raise `Inexact`; UInt64
/// inputs never overflow F64.
pub fn ui64_to_f64(context : Context, a : UInt64) -> SoftResult[F64] {
  if a == 0UL {
    { value: F64::from_bits(0UL), context }
  } else if (a & 0x8000000000000000UL) != 0UL {
    round_pack_to_f64(context, false, 0x43D, short_shift_right_jam64(a, 1))
  } else {
    norm_round_pack_to_f64(context, false, 0x43C, a)
  }
}

///|
/// Converts a signed 64-bit integer to F64 with SoftFloat rounding.
///
/// The full Int64 range is finite in binary64. Values whose magnitude needs
/// more than 53 precision bits may raise `Inexact`; no `Invalid` or `Overflow`
/// flag is raised.
pub fn i64_to_f64(context : Context, a : Int64) -> SoftResult[F64] {
  let sign = a < 0L
  let bits = a.reinterpret_as_uint64()
  if (bits & 0x7FFFFFFFFFFFFFFFUL) == 0UL {
    {
      value: F64::from_bits(
        if sign {
          pack_to_f64_ui(true, 0x43E, 0UL)
        } else {
          0UL
        },
      ),
      context,
    }
  } else {
    let (_, abs_a) = abs_i64_bits(a)
    norm_round_pack_to_f64(context, sign, 0x43C, abs_a)
  }
}
