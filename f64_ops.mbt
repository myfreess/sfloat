///|
fn f64_propagate_nan_result(
  context : Context,
  ui_a : UInt64,
  ui_b : UInt64,
) -> SoftResult[F64] {
  let propagated = propagate_nan_f64_ui(context, ui_a, ui_b)
  { value: F64::from_bits(propagated.value), context: propagated.context }
}

///|
/// Converts F64 to F16 with SoftFloat rounding, tininess, and NaN handling.
///
/// Signaling NaNs raise `Invalid`; finite values may raise `Inexact`,
/// `Underflow`, or `Overflow | Inexact` as they round into binary16. Signed
/// zeros and infinities keep their sign. Overflow returns infinity or the
/// largest finite F16 according to `context.rounding`.
pub fn F64::to_f16(self : F64, context : Context) -> SoftResult[F16] {
  let bits = self.to_bits()
  let sign = sign_f64_ui(bits)
  let exp = exp_f64_ui(bits)
  let frac = frac_f64_ui(bits)
  if exp == 0x7FF {
    if frac != 0UL {
      let common = f64_ui_to_common_nan(context, bits)
      {
        value: F16::from_bits(
          common_nan_to_f16_ui(common.context, common.value),
        ),
        context: common.context,
      }
    } else {
      { value: F16::from_bits(pack_to_f16_ui(sign, 0x1F, 0)), context }
    }
  } else {
    let frac16 = short_shift_right_jam64(frac, 38).to_uint()
    if (exp.to_uint64() | frac16.to_uint64()) == 0UL {
      { value: F16::from_bits(pack_to_f16_ui(sign, 0, 0)), context }
    } else {
      round_pack_to_f16(context, sign, exp - 0x3F1, frac16 | 0x4000U)
    }
  }
}

///|
/// Converts F64 to F32 with SoftFloat rounding, tininess, and NaN handling.
///
/// The selected specialization controls NaN payload/default behavior and
/// signaling-NaN invalid flags. Signed zeros and infinities keep their sign.
/// Finite values may raise `Inexact`, `Underflow`, or `Overflow | Inexact`;
/// overflow follows the destination format's rounding rules.
pub fn F64::to_f32(self : F64, context : Context) -> SoftResult[F32] {
  let bits = self.to_bits()
  let sign = sign_f64_ui(bits)
  let exp = exp_f64_ui(bits)
  let frac = frac_f64_ui(bits)
  if exp == 0x7FF {
    if frac != 0UL {
      let common = f64_ui_to_common_nan(context, bits)
      {
        value: F32::from_bits(
          common_nan_to_f32_ui(common.context, common.value),
        ),
        context: common.context,
      }
    } else {
      { value: F32::from_bits(pack_to_f32_ui(sign, 0xFF, 0U)), context }
    }
  } else {
    let frac32 = short_shift_right_jam64(frac, 22).to_uint()
    if (exp.to_uint64() | frac32.to_uint64()) == 0UL {
      { value: F32::from_bits(pack_to_f32_ui(sign, 0, 0U)), context }
    } else {
      round_pack_to_f32(context, sign, exp - 0x381, frac32 | 0x40000000U)
    }
  }
}

///|
/// Function-style wrapper for SoftFloat `f64_to_f16`.
///
/// Equivalent to `a.to_f16(context)`.
pub fn f64_to_f16(context : Context, a : F64) -> SoftResult[F16] {
  a.to_f16(context)
}

///|
/// Function-style wrapper for SoftFloat `f64_to_f32`.
///
/// Equivalent to `a.to_f32(context)`.
pub fn f64_to_f32(context : Context, a : F64) -> SoftResult[F32] {
  a.to_f32(context)
}

///|
/// Function-style F64 signaling-NaN predicate wrapper.
///
/// Equivalent to `a.is_signaling_nan()` and raises no flags.
pub fn f64_is_signaling_nan(a : F64) -> Bool {
  a.is_signaling_nan()
}

///|
fn f64_invalid_ui32_result(
  context : Context,
  sign : Bool,
  is_nan : Bool,
) -> SoftResult[UInt] {
  let value = if is_nan {
    ui32_from_nan(context.specialization)
  } else if sign {
    ui32_from_neg_overflow(context.specialization)
  } else {
    ui32_from_pos_overflow(context.specialization)
  }
  { value, context: context.raise_flags(ExceptionFlags::invalid()) }
}

///|
fn f64_invalid_i32_result(
  context : Context,
  sign : Bool,
  is_nan : Bool,
) -> SoftResult[Int] {
  let value = if is_nan {
    i32_from_nan(context.specialization)
  } else if sign {
    i32_from_neg_overflow(context.specialization)
  } else {
    i32_from_pos_overflow(context.specialization)
  }
  { value, context: context.raise_flags(ExceptionFlags::invalid()) }
}

///|
fn f64_invalid_ui64_result(
  context : Context,
  sign : Bool,
  is_nan : Bool,
) -> SoftResult[UInt64] {
  let value = if is_nan {
    ui64_from_nan(context.specialization)
  } else if sign {
    ui64_from_neg_overflow(context.specialization)
  } else {
    ui64_from_pos_overflow(context.specialization)
  }
  { value, context: context.raise_flags(ExceptionFlags::invalid()) }
}

///|
fn f64_invalid_i64_result(
  context : Context,
  sign : Bool,
  is_nan : Bool,
) -> SoftResult[Int64] {
  let value = if is_nan {
    i64_from_nan(context.specialization)
  } else if sign {
    i64_from_neg_overflow(context.specialization)
  } else {
    i64_from_pos_overflow(context.specialization)
  }
  { value, context: context.raise_flags(ExceptionFlags::invalid()) }
}

///|
/// Converts F64 to unsigned 32-bit integer with operation-local rounding.
///
/// `exact` controls whether rounded finite inputs raise `Inexact`; NaNs,
/// negative nonzero values, infinities, and values outside UInt32 after
/// rounding raise `Invalid`. Negative zero converts to `0`; invalid result
/// constants follow the selected specialization.
pub fn F64::to_ui32(
  self : F64,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[UInt] {
  let bits = self.to_bits()
  let sign = sign_f64_ui(bits)
  let exp = exp_f64_ui(bits)
  let mut sig = frac_f64_ui(bits)
  if exp == 0x7FF && sig != 0UL {
    f64_invalid_ui32_result(context, sign, true)
  } else {
    if exp != 0 {
      sig = sig | 0x0010000000000000UL
    }
    let shift_dist = 0x427 - exp
    if shift_dist > 0 {
      sig = shift_right_jam64(sig, shift_dist)
    }
    round_to_ui32(context, sign, sig, rounding, exact)
  }
}

///|
/// Converts F64 to signed 32-bit integer with operation-local rounding.
///
/// NaNs, infinities, and values outside Int32 after rounding raise `Invalid`.
/// The exact value `-2147483648` is valid. Invalid integer result constants
/// follow `context.specialization`; `exact` only controls finite fractional
/// `Inexact`.
pub fn F64::to_i32(
  self : F64,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[Int] {
  let bits = self.to_bits()
  let sign = sign_f64_ui(bits)
  let exp = exp_f64_ui(bits)
  let mut sig = frac_f64_ui(bits)
  if exp == 0x7FF && sig != 0UL {
    f64_invalid_i32_result(context, sign, true)
  } else {
    if exp != 0 {
      sig = sig | 0x0010000000000000UL
    }
    let shift_dist = 0x427 - exp
    if shift_dist > 0 {
      sig = shift_right_jam64(sig, shift_dist)
    }
    round_to_i32(context, sign, sig, rounding, exact)
  }
}

///|
/// Converts F64 to unsigned 64-bit integer with operation-local rounding.
///
/// Negative nonzero values, NaNs, infinities, and values outside UInt64 after
/// rounding raise `Invalid`; negative zero converts to `0`. Fractional finite
/// inputs raise `Inexact` only when `exact` is true.
pub fn F64::to_ui64(
  self : F64,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[UInt64] {
  let bits = self.to_bits()
  let sign = sign_f64_ui(bits)
  let exp = exp_f64_ui(bits)
  let frac = frac_f64_ui(bits)
  let mut sig = frac
  if exp != 0 {
    sig = sig | 0x0010000000000000UL
  }
  let shift_dist = 0x433 - exp
  if shift_dist <= 0 {
    if shift_dist < -11 {
      f64_invalid_ui64_result(context, sign, exp == 0x7FF && frac != 0UL)
    } else {
      round_to_ui64(context, sign, sig << -shift_dist, 0UL, rounding, exact)
    }
  } else {
    let shifted = shift_right_jam64_extra(sig, 0UL, shift_dist)
    round_to_ui64(context, sign, shifted.value, shifted.extra, rounding, exact)
  }
}

///|
/// Converts F64 to signed 64-bit integer with operation-local rounding.
///
/// NaNs, infinities, and values outside Int64 after rounding raise `Invalid`.
/// The exact lower bound `-9223372036854775808` is accepted. Invalid result
/// constants follow `context.specialization`.
pub fn F64::to_i64(
  self : F64,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[Int64] {
  let bits = self.to_bits()
  let sign = sign_f64_ui(bits)
  let exp = exp_f64_ui(bits)
  let frac = frac_f64_ui(bits)
  let mut sig = frac
  if exp != 0 {
    sig = sig | 0x0010000000000000UL
  }
  let shift_dist = 0x433 - exp
  if shift_dist <= 0 {
    if shift_dist < -11 {
      f64_invalid_i64_result(context, sign, exp == 0x7FF && frac != 0UL)
    } else {
      round_to_i64(context, sign, sig << -shift_dist, 0UL, rounding, exact)
    }
  } else {
    let shifted = shift_right_jam64_extra(sig, 0UL, shift_dist)
    round_to_i64(context, sign, shifted.value, shifted.extra, rounding, exact)
  }
}

///|
/// Converts F64 to unsigned 32-bit integer using round-minMag.
///
/// This `_r_minMag` form truncates finite values toward zero regardless of
/// `context.rounding`. Magnitudes below 1 return `0` and may raise `Inexact`.
/// Negative nonzero values, NaNs, infinities, and out-of-range values raise
/// `Invalid`.
pub fn F64::to_ui32_min_mag(
  self : F64,
  context : Context,
  exact : Bool,
) -> SoftResult[UInt] {
  let bits = self.to_bits()
  let exp = exp_f64_ui(bits)
  let mut sig = frac_f64_ui(bits)
  let shift_dist = 0x433 - exp
  if shift_dist >= 53 {
    let context = if exact && (exp != 0 || sig != 0UL) {
      context.raise_flags(ExceptionFlags::inexact())
    } else {
      context
    }
    { value: 0U, context }
  } else {
    let sign = sign_f64_ui(bits)
    if sign || shift_dist < 21 {
      f64_invalid_ui32_result(context, sign, exp == 0x7FF && sig != 0UL)
    } else {
      sig = sig | 0x0010000000000000UL
      let value = (sig >> shift_dist).to_uint()
      let context = if exact && value.to_uint64() << shift_dist != sig {
        context.raise_flags(ExceptionFlags::inexact())
      } else {
        context
      }
      { value, context }
    }
  }
}

///|
/// Converts F64 to signed 32-bit integer using round-minMag.
///
/// Finite values truncate toward zero. The exact lower bound `-2147483648` is
/// accepted; values beyond Int32, NaNs, and infinities raise `Invalid`.
/// `exact` controls `Inexact` for discarded fractional bits.
pub fn F64::to_i32_min_mag(
  self : F64,
  context : Context,
  exact : Bool,
) -> SoftResult[Int] {
  let bits = self.to_bits()
  let exp = exp_f64_ui(bits)
  let mut sig = frac_f64_ui(bits)
  let shift_dist = 0x433 - exp
  if shift_dist >= 53 {
    let context = if exact && (exp != 0 || sig != 0UL) {
      context.raise_flags(ExceptionFlags::inexact())
    } else {
      context
    }
    { value: 0, context }
  } else {
    let sign = sign_f64_ui(bits)
    if shift_dist < 22 {
      if sign && exp == 0x41E && sig < 0x0000000000200000UL {
        let context = if exact && sig != 0UL {
          context.raise_flags(ExceptionFlags::inexact())
        } else {
          context
        }
        { value: -0x7FFFFFFF - 1, context }
      } else {
        f64_invalid_i32_result(context, sign, exp == 0x7FF && sig != 0UL)
      }
    } else {
      sig = sig | 0x0010000000000000UL
      let abs_value = (sig >> shift_dist).to_uint().reinterpret_as_int()
      let context = if exact &&
        abs_value.reinterpret_as_uint().to_uint64() << shift_dist != sig {
        context.raise_flags(ExceptionFlags::inexact())
      } else {
        context
      }
      { value: if sign { -abs_value } else { abs_value }, context }
    }
  }
}

///|
/// Converts F64 to unsigned 64-bit integer using round-minMag.
///
/// Finite values truncate toward zero. Magnitudes below 1 return `0`; negative
/// nonzero, NaN, infinity, and out-of-range inputs raise `Invalid`.
pub fn F64::to_ui64_min_mag(
  self : F64,
  context : Context,
  exact : Bool,
) -> SoftResult[UInt64] {
  let bits = self.to_bits()
  let sign = sign_f64_ui(bits)
  let exp = exp_f64_ui(bits)
  let mut sig = frac_f64_ui(bits)
  let shift_dist = 0x433 - exp
  if shift_dist >= 53 {
    let context = if exact && (exp != 0 || sig != 0UL) {
      context.raise_flags(ExceptionFlags::inexact())
    } else {
      context
    }
    { value: 0UL, context }
  } else if sign || shift_dist < -11 {
    f64_invalid_ui64_result(context, sign, exp == 0x7FF && sig != 0UL)
  } else {
    sig = sig | 0x0010000000000000UL
    if shift_dist <= 0 {
      { value: sig << -shift_dist, context }
    } else {
      let value = sig >> shift_dist
      let context = if exact && sig << (-shift_dist & 63) != 0UL {
        context.raise_flags(ExceptionFlags::inexact())
      } else {
        context
      }
      { value, context }
    }
  }
}

///|
/// Converts F64 to signed 64-bit integer using round-minMag.
///
/// Finite values truncate toward zero. The exact lower bound
/// `-9223372036854775808` is accepted; values beyond Int64, NaNs, and
/// infinities raise `Invalid`. `exact` controls `Inexact` for discarded
/// fractional bits.
pub fn F64::to_i64_min_mag(
  self : F64,
  context : Context,
  exact : Bool,
) -> SoftResult[Int64] {
  let bits = self.to_bits()
  let sign = sign_f64_ui(bits)
  let exp = exp_f64_ui(bits)
  let mut sig = frac_f64_ui(bits)
  let shift_dist = 0x433 - exp
  if shift_dist <= 0 {
    if shift_dist < -10 {
      if bits == pack_to_f64_ui(true, 0x43E, 0UL) {
        { value: -0x7FFFFFFFFFFFFFFFL - 1L, context }
      } else {
        f64_invalid_i64_result(context, sign, exp == 0x7FF && sig != 0UL)
      }
    } else {
      sig = sig | 0x0010000000000000UL
      let abs_value = (sig << -shift_dist).reinterpret_as_int64()
      { value: if sign { -abs_value } else { abs_value }, context }
    }
  } else if shift_dist >= 53 {
    let context = if exact && (exp != 0 || sig != 0UL) {
      context.raise_flags(ExceptionFlags::inexact())
    } else {
      context
    }
    { value: 0L, context }
  } else {
    sig = sig | 0x0010000000000000UL
    let abs_value = (sig >> shift_dist).reinterpret_as_int64()
    let context = if exact &&
      abs_value.reinterpret_as_uint64() << shift_dist != sig {
      context.raise_flags(ExceptionFlags::inexact())
    } else {
      context
    }
    { value: if sign { -abs_value } else { abs_value }, context }
  }
}

///|
/// Rounds F64 to an integral F64 value with operation-local rounding.
///
/// `exact` controls whether a changed finite value raises `Inexact`; NaNs are
/// propagated according to `context.specialization`. Infinities and already
/// integral finite values are returned unchanged. Values with magnitude below
/// 1 round to signed zero or signed one according to `rounding`; no overflow or
/// underflow flag is raised.
pub fn F64::round_to_int(
  self : F64,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[F64] {
  let ui_a = self.to_bits()
  let exp = exp_f64_ui(ui_a)
  if exp <= 0x3FE {
    if (ui_a & 0x7FFFFFFFFFFFFFFFUL) == 0UL {
      return { value: self, context }
    }
    let mut context = context
    if exact {
      context = context.raise_flags(ExceptionFlags::inexact())
    }
    let mut ui_z = ui_a & pack_to_f64_ui(true, 0, 0UL)
    match rounding {
      NearEven =>
        if frac_f64_ui(ui_a) != 0UL && exp == 0x3FE {
          ui_z = ui_z | pack_to_f64_ui(false, 0x3FF, 0UL)
        }
      NearMaxMag =>
        if exp == 0x3FE {
          ui_z = ui_z | pack_to_f64_ui(false, 0x3FF, 0UL)
        }
      Min => if ui_z != 0UL { ui_z = pack_to_f64_ui(true, 0x3FF, 0UL) }
      Max => if ui_z == 0UL { ui_z = pack_to_f64_ui(false, 0x3FF, 0UL) }
      Odd => ui_z = ui_z | pack_to_f64_ui(false, 0x3FF, 0UL)
      MinMag => ()
    }
    { value: F64::from_bits(ui_z), context }
  } else if exp >= 0x433 {
    if exp == 0x7FF && frac_f64_ui(ui_a) != 0UL {
      f64_propagate_nan_result(context, ui_a, 0UL)
    } else {
      { value: self, context }
    }
  } else {
    let mut ui_z = ui_a
    let last_bit_mask = 1UL << (0x433 - exp)
    let round_bits_mask = last_bit_mask - 1UL
    let directed_rounding = if sign_f64_ui(ui_z) { Min } else { Max }
    if rounding == NearMaxMag {
      ui_z = ui_z + (last_bit_mask >> 1)
    } else if rounding == NearEven {
      ui_z = ui_z + (last_bit_mask >> 1)
      if (ui_z & round_bits_mask) == 0UL {
        ui_z = ui_z & (0xFFFFFFFFFFFFFFFFUL - last_bit_mask)
      }
    } else if rounding == directed_rounding {
      ui_z = ui_z + round_bits_mask
    }
    ui_z = ui_z & (0xFFFFFFFFFFFFFFFFUL - round_bits_mask)
    let mut context = context
    if ui_z != ui_a {
      if rounding == Odd {
        ui_z = ui_z | last_bit_mask
      }
      if exact {
        context = context.raise_flags(ExceptionFlags::inexact())
      }
    }
    { value: F64::from_bits(ui_z), context }
  }
}

///|
/// Function-style F64 round-to-integral wrapper for `f64_roundToInt`.
///
/// Equivalent to `a.round_to_int(context, rounding, exact)`.
pub fn f64_round_to_int(
  context : Context,
  a : F64,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[F64] {
  a.round_to_int(context, rounding, exact)
}

///|
/// Function-style wrapper for SoftFloat `f64_to_ui32`.
///
/// Equivalent to `a.to_ui32(context, rounding, exact)`.
pub fn f64_to_ui32(
  context : Context,
  a : F64,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[UInt] {
  a.to_ui32(context, rounding, exact)
}

///|
/// Function-style wrapper for SoftFloat `f64_to_ui64`.
///
/// Equivalent to `a.to_ui64(context, rounding, exact)`.
pub fn f64_to_ui64(
  context : Context,
  a : F64,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[UInt64] {
  a.to_ui64(context, rounding, exact)
}

///|
/// Function-style wrapper for SoftFloat `f64_to_i32`.
///
/// Equivalent to `a.to_i32(context, rounding, exact)`.
pub fn f64_to_i32(
  context : Context,
  a : F64,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[Int] {
  a.to_i32(context, rounding, exact)
}

///|
/// Function-style wrapper for SoftFloat `f64_to_i64`.
///
/// Equivalent to `a.to_i64(context, rounding, exact)`.
pub fn f64_to_i64(
  context : Context,
  a : F64,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[Int64] {
  a.to_i64(context, rounding, exact)
}

///|
/// Function-style wrapper for SoftFloat `f64_to_ui32_r_minMag`.
///
/// Equivalent to `a.to_ui32_min_mag(context, exact)`.
pub fn f64_to_ui32_min_mag(
  context : Context,
  a : F64,
  exact : Bool,
) -> SoftResult[UInt] {
  a.to_ui32_min_mag(context, exact)
}

///|
/// Function-style wrapper for SoftFloat `f64_to_ui64_r_minMag`.
///
/// Equivalent to `a.to_ui64_min_mag(context, exact)`.
pub fn f64_to_ui64_min_mag(
  context : Context,
  a : F64,
  exact : Bool,
) -> SoftResult[UInt64] {
  a.to_ui64_min_mag(context, exact)
}

///|
/// Function-style wrapper for SoftFloat `f64_to_i32_r_minMag`.
///
/// Equivalent to `a.to_i32_min_mag(context, exact)`.
pub fn f64_to_i32_min_mag(
  context : Context,
  a : F64,
  exact : Bool,
) -> SoftResult[Int] {
  a.to_i32_min_mag(context, exact)
}

///|
/// Function-style wrapper for SoftFloat `f64_to_i64_r_minMag`.
///
/// Equivalent to `a.to_i64_min_mag(context, exact)`.
pub fn f64_to_i64_min_mag(
  context : Context,
  a : F64,
  exact : Bool,
) -> SoftResult[Int64] {
  a.to_i64_min_mag(context, exact)
}

///|
fn f64_both_zero(a : UInt64, b : UInt64) -> Bool {
  ((a | b) & 0x7FFFFFFFFFFFFFFFUL) == 0UL
}

///|
fn f64_ordered_le(a : UInt64, b : UInt64) -> Bool {
  let sign_a = sign_f64_ui(a)
  let sign_b = sign_f64_ui(b)
  if sign_a != sign_b {
    sign_a || f64_both_zero(a, b)
  } else {
    a == b || sign_a != (a < b)
  }
}

///|
fn f64_ordered_lt(a : UInt64, b : UInt64) -> Bool {
  let sign_a = sign_f64_ui(a)
  let sign_b = sign_f64_ui(b)
  if sign_a != sign_b {
    sign_a && !f64_both_zero(a, b)
  } else {
    a != b && sign_a != (a < b)
  }
}

///|
fn f64_compare_nan_context(
  context : Context,
  a : UInt64,
  b : UInt64,
  quiet : Bool,
) -> Context {
  if is_nan_f64_ui(a) || is_nan_f64_ui(b) {
    if !quiet || is_sig_nan_f64_ui(a) || is_sig_nan_f64_ui(b) {
      context.raise_flags(ExceptionFlags::invalid())
    } else {
      context
    }
  } else {
    context
  }
}

///|
/// Implements SoftFloat `f64_eq`.
///
/// Quiet NaNs compare false; signaling NaNs raise `Invalid`. `+0` and `-0`
/// compare equal.
pub fn f64_eq(context : Context, a : F64, b : F64) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  let context = f64_compare_nan_context(context, ui_a, ui_b, true)
  if is_nan_f64_ui(ui_a) || is_nan_f64_ui(ui_b) {
    { value: false, context }
  } else {
    { value: ui_a == ui_b || f64_both_zero(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f64_eq_signaling`.
///
/// Any NaN operand raises `Invalid` and compares false. `+0` and `-0` compare
/// equal.
pub fn f64_eq_signaling(
  context : Context,
  a : F64,
  b : F64,
) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  let context = f64_compare_nan_context(context, ui_a, ui_b, false)
  if is_nan_f64_ui(ui_a) || is_nan_f64_ui(ui_b) {
    { value: false, context }
  } else {
    { value: ui_a == ui_b || f64_both_zero(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f64_le`.
///
/// Any NaN operand raises `Invalid` and compares false. Signed zeros compare
/// equal, so both zero orderings are true for less-or-equal.
pub fn f64_le(context : Context, a : F64, b : F64) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  if is_nan_f64_ui(ui_a) || is_nan_f64_ui(ui_b) {
    { value: false, context: context.raise_flags(ExceptionFlags::invalid()) }
  } else {
    { value: f64_ordered_le(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f64_lt`.
///
/// Any NaN operand raises `Invalid` and compares false. Signed zeros compare
/// equal, so neither zero is less than the other.
pub fn f64_lt(context : Context, a : F64, b : F64) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  if is_nan_f64_ui(ui_a) || is_nan_f64_ui(ui_b) {
    { value: false, context: context.raise_flags(ExceptionFlags::invalid()) }
  } else {
    { value: f64_ordered_lt(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f64_le_quiet`.
///
/// Quiet NaNs compare false without flags; signaling NaNs raise `Invalid`.
/// Signed zeros compare equal.
pub fn f64_le_quiet(context : Context, a : F64, b : F64) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  let context = f64_compare_nan_context(context, ui_a, ui_b, true)
  if is_nan_f64_ui(ui_a) || is_nan_f64_ui(ui_b) {
    { value: false, context }
  } else {
    { value: f64_ordered_le(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f64_lt_quiet`.
///
/// Quiet NaNs compare false without flags; signaling NaNs raise `Invalid`.
/// Signed zeros compare equal, so zero-vs-zero is never less-than.
pub fn f64_lt_quiet(context : Context, a : F64, b : F64) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  let context = f64_compare_nan_context(context, ui_a, ui_b, true)
  if is_nan_f64_ui(ui_a) || is_nan_f64_ui(ui_b) {
    { value: false, context }
  } else {
    { value: f64_ordered_lt(ui_a, ui_b), context }
  }
}
