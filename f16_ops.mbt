///|
/// Converts F16 to F32 with SoftFloat NaN and subnormal handling.
///
/// The conversion is exact for all finite F16 inputs, including signed zeros
/// and subnormals. Infinities keep their sign. NaNs use the selected
/// specialization's common-NaN conversion; signaling NaNs raise `Invalid`.
pub fn F16::to_f32(self : F16, context : Context) -> SoftResult[F32] {
  let bits = self.to_bits()
  let sign = sign_f16_ui(bits)
  let mut exp = exp_f16_ui(bits)
  let mut frac = frac_f16_ui(bits)
  if exp == 0x1F {
    if frac != 0 {
      let common = f16_ui_to_common_nan(context, bits)
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
    if exp == 0 {
      if frac == 0 {
        return { value: F32::from_bits(pack_to_f32_ui(sign, 0, 0U)), context }
      }
      let norm = norm_subnormal_f16_sig(frac)
      exp = norm.exp - 1
      frac = norm.sig
    }
    {
      value: F32::from_bits(
        pack_to_f32_ui(sign, exp + 0x70, frac.to_uint() << 13),
      ),
      context,
    }
  }
}

///|
/// Converts F16 to F64 with SoftFloat NaN and subnormal handling.
///
/// The conversion is exact for all finite F16 inputs, including signed zeros
/// and subnormals. Infinities keep their sign. NaNs use the selected
/// specialization's common-NaN conversion; signaling NaNs raise `Invalid`.
pub fn F16::to_f64(self : F16, context : Context) -> SoftResult[F64] {
  let bits = self.to_bits()
  let sign = sign_f16_ui(bits)
  let mut exp = exp_f16_ui(bits)
  let mut frac = frac_f16_ui(bits)
  if exp == 0x1F {
    if frac != 0 {
      let common = f16_ui_to_common_nan(context, bits)
      {
        value: F64::from_bits(
          common_nan_to_f64_ui(common.context, common.value),
        ),
        context: common.context,
      }
    } else {
      { value: F64::from_bits(pack_to_f64_ui(sign, 0x7FF, 0UL)), context }
    }
  } else {
    if exp == 0 {
      if frac == 0 {
        return { value: F64::from_bits(pack_to_f64_ui(sign, 0, 0UL)), context }
      }
      let norm = norm_subnormal_f16_sig(frac)
      exp = norm.exp - 1
      frac = norm.sig
    }
    {
      value: F64::from_bits(
        pack_to_f64_ui(sign, exp + 0x3F0, frac.to_uint64() << 42),
      ),
      context,
    }
  }
}

///|
/// Function-style F16-to-F32 wrapper for the SoftFloat C symbol.
///
/// Equivalent to `a.to_f32(context)`, including exact finite conversion and
/// signaling-NaN invalid flag behavior.
pub fn f16_to_f32(context : Context, a : F16) -> SoftResult[F32] {
  a.to_f32(context)
}

///|
/// Function-style F16-to-F64 wrapper for the SoftFloat C symbol.
///
/// Equivalent to `a.to_f64(context)` with no extra rounding or flag handling.
pub fn f16_to_f64(context : Context, a : F16) -> SoftResult[F64] {
  a.to_f64(context)
}

///|
/// Function-style F16 signaling-NaN predicate wrapper.
///
/// Equivalent to `a.is_signaling_nan()` and raises no flags.
pub fn f16_is_signaling_nan(a : F16) -> Bool {
  a.is_signaling_nan()
}

///|
fn f16_invalid_ui32_result(
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
fn f16_invalid_ui64_result(
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
fn f16_invalid_i32_result(
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
fn f16_invalid_i64_result(
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
fn f16_integer_fields(a : F16) -> (Bool, Int, UInt) {
  let bits = a.to_bits()
  (sign_f16_ui(bits), exp_f16_ui(bits), frac_f16_ui(bits).to_uint())
}

///|
/// Converts F16 to unsigned 32-bit integer with operation-local rounding.
///
/// All nonnegative finite F16 values fit in UInt32. Negative zero converts to
/// `0`; negative nonzero values raise `Invalid` and return the specialization's
/// unsigned negative-overflow result. NaNs and infinities raise `Invalid`.
/// `exact` controls whether discarded fractional bits raise `Inexact`.
pub fn F16::to_ui32(
  self : F16,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[UInt] {
  let (sign, exp, frac) = f16_integer_fields(self)
  if exp == 0x1F {
    f16_invalid_ui32_result(context, sign, frac != 0U)
  } else {
    let mut sig32 = frac
    if exp != 0 {
      sig32 = sig32 | 0x0400U
      let shift_dist = exp - 0x19
      if shift_dist >= 0 && !sign {
        return { value: sig32 << shift_dist, context }
      }
      let shift_dist = exp - 0x0D
      if shift_dist > 0 {
        sig32 = sig32 << shift_dist
      }
    }
    round_to_ui32(context, sign, sig32.to_uint64(), rounding, exact)
  }
}

///|
/// Converts F16 to unsigned 64-bit integer with operation-local rounding.
///
/// All nonnegative finite F16 values fit in UInt64. Negative zero converts to
/// `0`; negative nonzero values, NaNs, and infinities raise `Invalid` and use
/// specialization-defined invalid result constants. `exact` only controls
/// `Inexact` for finite fractional inputs.
pub fn F16::to_ui64(
  self : F16,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[UInt64] {
  let (sign, exp, frac) = f16_integer_fields(self)
  if exp == 0x1F {
    f16_invalid_ui64_result(context, sign, frac != 0U)
  } else {
    let mut sig32 = frac
    if exp != 0 {
      sig32 = sig32 | 0x0400U
      let shift_dist = exp - 0x19
      if shift_dist >= 0 && !sign {
        return { value: sig32.to_uint64() << shift_dist, context }
      }
      let shift_dist = exp - 0x0D
      if shift_dist > 0 {
        sig32 = sig32 << shift_dist
      }
    }
    round_to_ui64(
      context,
      sign,
      sig32.to_uint64() >> 12,
      sig32.to_uint64() << 52,
      rounding,
      exact,
    )
  }
}

///|
/// Converts F16 to signed 32-bit integer with operation-local rounding.
///
/// Every finite F16 magnitude fits in Int32, so finite overflow is not a
/// boundary case for this conversion. NaNs and infinities raise `Invalid`;
/// finite fractional inputs raise `Inexact` only when `exact` is true.
pub fn F16::to_i32(
  self : F16,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[Int] {
  let (sign, exp, frac) = f16_integer_fields(self)
  if exp == 0x1F {
    f16_invalid_i32_result(context, sign, frac != 0U)
  } else {
    let mut sig32 = frac
    if exp != 0 {
      sig32 = sig32 | 0x0400U
      let shift_dist = exp - 0x19
      if shift_dist >= 0 {
        sig32 = sig32 << shift_dist
        let magnitude = sig32.reinterpret_as_int()
        return { value: if sign { -magnitude } else { magnitude }, context }
      }
      let shift_dist = exp - 0x0D
      if shift_dist > 0 {
        sig32 = sig32 << shift_dist
      }
    }
    round_to_i32(context, sign, sig32.to_uint64(), rounding, exact)
  }
}

///|
/// Converts F16 to signed 64-bit integer with operation-local rounding.
///
/// Every finite F16 value fits in Int64. NaNs and infinities raise `Invalid`;
/// otherwise the requested rounding mode determines how fractional bits are
/// discarded, and `exact` controls whether that loss raises `Inexact`.
pub fn F16::to_i64(
  self : F16,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[Int64] {
  let (sign, exp, frac) = f16_integer_fields(self)
  if exp == 0x1F {
    f16_invalid_i64_result(context, sign, frac != 0U)
  } else {
    let mut sig32 = frac
    if exp != 0 {
      sig32 = sig32 | 0x0400U
      let shift_dist = exp - 0x19
      if shift_dist >= 0 {
        sig32 = sig32 << shift_dist
        let magnitude = sig32.reinterpret_as_int().to_int64()
        return { value: if sign { -magnitude } else { magnitude }, context }
      }
      let shift_dist = exp - 0x0D
      if shift_dist > 0 {
        sig32 = sig32 << shift_dist
      }
    }
    let result = round_to_i32(context, sign, sig32.to_uint64(), rounding, exact)
    { value: result.value.to_int64(), context: result.context }
  }
}

///|
fn f16_to_ui_min_mag_parts(
  context : Context,
  a : F16,
  exact : Bool,
  wide : Bool,
) -> SoftResult[UInt64] {
  let (sign, exp, frac) = f16_integer_fields(a)
  let shift_dist = exp - 0x0F
  if shift_dist < 0 {
    let context = if exact && (exp != 0 || frac != 0U) {
      context.raise_flags(ExceptionFlags::inexact())
    } else {
      context
    }
    { value: 0UL, context }
  } else if sign || exp == 0x1F {
    let invalid = f16_invalid_ui64_result(
      context,
      sign,
      exp == 0x1F && frac != 0U,
    )
    {
      value: if wide {
        invalid.value
      } else {
        invalid.value & 0xFFFFFFFFUL
      },
      context: invalid.context,
    }
  } else {
    let aligned = (frac | 0x0400U) << shift_dist
    let context = if exact && (aligned & 0x3FFU) != 0U {
      context.raise_flags(ExceptionFlags::inexact())
    } else {
      context
    }
    { value: (aligned >> 10).to_uint64(), context }
  }
}

///|
/// Converts F16 to unsigned 32-bit integer with round-minMag.
///
/// This is the SoftFloat `_r_minMag` form: finite values are truncated toward
/// zero regardless of `context.rounding`. Magnitudes below 1 convert to `0`
/// and may raise `Inexact` when `exact` is true. Negative nonzero values,
/// NaNs, and infinities raise `Invalid`.
pub fn F16::to_ui32_min_mag(
  self : F16,
  context : Context,
  exact : Bool,
) -> SoftResult[UInt] {
  let result = f16_to_ui_min_mag_parts(context, self, exact, false)
  { value: result.value.to_uint(), context: result.context }
}

///|
/// Converts F16 to unsigned 64-bit integer with round-minMag.
///
/// Equivalent boundary behavior to `F16::to_ui32_min_mag`, but returning
/// UInt64. All nonnegative finite F16 values are in range.
pub fn F16::to_ui64_min_mag(
  self : F16,
  context : Context,
  exact : Bool,
) -> SoftResult[UInt64] {
  f16_to_ui_min_mag_parts(context, self, exact, true)
}

///|
fn f16_to_i_min_mag_parts(
  context : Context,
  a : F16,
  exact : Bool,
  wide : Bool,
) -> SoftResult[Int64] {
  let (sign, exp, frac) = f16_integer_fields(a)
  let shift_dist = exp - 0x0F
  if shift_dist < 0 {
    let context = if exact && (exp != 0 || frac != 0U) {
      context.raise_flags(ExceptionFlags::inexact())
    } else {
      context
    }
    { value: 0L, context }
  } else if exp == 0x1F {
    if wide {
      f16_invalid_i64_result(context, sign, frac != 0U)
    } else {
      let invalid = f16_invalid_i32_result(context, sign, frac != 0U)
      { value: invalid.value.to_int64(), context: invalid.context }
    }
  } else {
    let aligned = (frac | 0x0400U) << shift_dist
    let context = if exact && (aligned & 0x3FFU) != 0U {
      context.raise_flags(ExceptionFlags::inexact())
    } else {
      context
    }
    let value = (aligned >> 10).reinterpret_as_int().to_int64()
    { value: if sign { -value } else { value }, context }
  }
}

///|
/// Converts F16 to signed 32-bit integer with round-minMag.
///
/// Finite values truncate toward zero and all fit in Int32. Values with
/// magnitude below 1 return `0` and may raise `Inexact`; NaNs and infinities
/// raise `Invalid`.
pub fn F16::to_i32_min_mag(
  self : F16,
  context : Context,
  exact : Bool,
) -> SoftResult[Int] {
  let result = f16_to_i_min_mag_parts(context, self, exact, false)
  { value: result.value.to_int(), context: result.context }
}

///|
/// Converts F16 to signed 64-bit integer with round-minMag.
///
/// Finite values truncate toward zero and all fit in Int64. `exact` controls
/// the `Inexact` flag for discarded fractional bits; NaNs and infinities raise
/// `Invalid`.
pub fn F16::to_i64_min_mag(
  self : F16,
  context : Context,
  exact : Bool,
) -> SoftResult[Int64] {
  f16_to_i_min_mag_parts(context, self, exact, true)
}

///|
/// Function-style wrapper for SoftFloat `f16_to_ui32`.
///
/// Equivalent to `a.to_ui32(context, rounding, exact)`.
pub fn f16_to_ui32(
  context : Context,
  a : F16,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[UInt] {
  a.to_ui32(context, rounding, exact)
}

///|
/// Function-style wrapper for SoftFloat `f16_to_ui64`.
///
/// Equivalent to `a.to_ui64(context, rounding, exact)`.
pub fn f16_to_ui64(
  context : Context,
  a : F16,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[UInt64] {
  a.to_ui64(context, rounding, exact)
}

///|
/// Function-style wrapper for SoftFloat `f16_to_i32`.
///
/// Equivalent to `a.to_i32(context, rounding, exact)`.
pub fn f16_to_i32(
  context : Context,
  a : F16,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[Int] {
  a.to_i32(context, rounding, exact)
}

///|
/// Function-style wrapper for SoftFloat `f16_to_i64`.
///
/// Equivalent to `a.to_i64(context, rounding, exact)`.
pub fn f16_to_i64(
  context : Context,
  a : F16,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[Int64] {
  a.to_i64(context, rounding, exact)
}

///|
/// Function-style wrapper for SoftFloat `f16_to_ui32_r_minMag`.
///
/// Equivalent to `a.to_ui32_min_mag(context, exact)`.
pub fn f16_to_ui32_min_mag(
  context : Context,
  a : F16,
  exact : Bool,
) -> SoftResult[UInt] {
  a.to_ui32_min_mag(context, exact)
}

///|
/// Function-style wrapper for SoftFloat `f16_to_ui64_r_minMag`.
///
/// Equivalent to `a.to_ui64_min_mag(context, exact)`.
pub fn f16_to_ui64_min_mag(
  context : Context,
  a : F16,
  exact : Bool,
) -> SoftResult[UInt64] {
  a.to_ui64_min_mag(context, exact)
}

///|
/// Function-style wrapper for SoftFloat `f16_to_i32_r_minMag`.
///
/// Equivalent to `a.to_i32_min_mag(context, exact)`.
pub fn f16_to_i32_min_mag(
  context : Context,
  a : F16,
  exact : Bool,
) -> SoftResult[Int] {
  a.to_i32_min_mag(context, exact)
}

///|
/// Function-style wrapper for SoftFloat `f16_to_i64_r_minMag`.
///
/// Equivalent to `a.to_i64_min_mag(context, exact)`.
pub fn f16_to_i64_min_mag(
  context : Context,
  a : F16,
  exact : Bool,
) -> SoftResult[Int64] {
  a.to_i64_min_mag(context, exact)
}

///|
/// Rounds F16 to an integral F16 value with an operation-local rounding mode.
///
/// This ports SoftFloat `f16_roundToInt`: `exact` controls whether rounded
/// finite inputs raise `Inexact`; NaNs are propagated through the selected
/// specialization. Infinities and finite values already integral are returned
/// unchanged. Inputs with magnitude below 1 round to signed zero or signed one
/// according to `rounding`; no overflow or underflow flag is raised.
pub fn F16::round_to_int(
  self : F16,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[F16] {
  let ui_a = self.to_bits()
  let exp = exp_f16_ui(ui_a)
  if exp <= 0x0E {
    if ((ui_a.to_uint() << 1) & 0xFFFFU) == 0U {
      return { value: self, context }
    }
    let mut context = context
    if exact {
      context = context.raise_flags(ExceptionFlags::inexact())
    }
    let mut ui_z = ui_a & pack_to_f16_ui(true, 0, 0)
    match rounding {
      NearEven =>
        if frac_f16_ui(ui_a) != 0 && exp == 0x0E {
          ui_z = ui_z | pack_to_f16_ui(false, 0x0F, 0)
        }
      NearMaxMag =>
        if exp == 0x0E {
          ui_z = ui_z | pack_to_f16_ui(false, 0x0F, 0)
        }
      Min => if ui_z != 0 { ui_z = pack_to_f16_ui(true, 0x0F, 0) }
      Max => if ui_z == 0 { ui_z = pack_to_f16_ui(false, 0x0F, 0) }
      Odd => ui_z = ui_z | pack_to_f16_ui(false, 0x0F, 0)
      MinMag => ()
    }
    { value: F16::from_bits(ui_z), context }
  } else if exp >= 0x19 {
    if exp == 0x1F && frac_f16_ui(ui_a) != 0 {
      let propagated = propagate_nan_f16_ui(context, ui_a, 0)
      { value: F16::from_bits(propagated.value), context: propagated.context }
    } else {
      { value: self, context }
    }
  } else {
    let mut ui_z = ui_a
    let last_bit_mask = (1 << (0x19 - exp)).to_uint16()
    let round_bits_mask = last_bit_mask - 1
    let directed_rounding = if sign_f16_ui(ui_z) { Min } else { Max }
    if rounding == NearMaxMag {
      ui_z = ui_z + (last_bit_mask >> 1)
    } else if rounding == NearEven {
      ui_z = ui_z + (last_bit_mask >> 1)
      if (ui_z & round_bits_mask) == 0 {
        ui_z = ui_z & (0xFFFF - last_bit_mask)
      }
    } else if rounding == directed_rounding {
      ui_z = ui_z + round_bits_mask
    }
    ui_z = ui_z & (0xFFFF - round_bits_mask)
    let mut context = context
    if ui_z != ui_a {
      if rounding == Odd {
        ui_z = ui_z | last_bit_mask
      }
      if exact {
        context = context.raise_flags(ExceptionFlags::inexact())
      }
    }
    { value: F16::from_bits(ui_z), context }
  }
}

///|
/// Function-style F16 round-to-integral wrapper for the SoftFloat C symbol.
///
/// Equivalent to `a.round_to_int(context, rounding, exact)`.
pub fn f16_round_to_int(
  context : Context,
  a : F16,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[F16] {
  a.round_to_int(context, rounding, exact)
}

///|
fn f16_add_epsilon(context : Context, ui_z : UInt16) -> SoftResult[F16] {
  let mut context = context
  let mut ui_z = ui_z
  if context.rounding != NearEven {
    let directed_rounding = if sign_f16_ui(ui_z) { Min } else { Max }
    if context.rounding == directed_rounding {
      ui_z = ui_z + 1
      if ((ui_z.to_uint() << 1) & 0xFFFFU) == 0xF800U {
        context = context.raise_flags(
          ExceptionFlags::overflow().merge(ExceptionFlags::inexact()),
        )
      }
    } else if context.rounding == Odd {
      ui_z = ui_z | 1
    }
  }
  {
    value: F16::from_bits(ui_z),
    context: context.raise_flags(ExceptionFlags::inexact()),
  }
}

///|
fn f16_sub_epsilon(context : Context, ui_z : UInt16) -> SoftResult[F16] {
  let mut ui_z = ui_z
  if context.rounding != NearEven {
    let directed_rounding = if sign_f16_ui(ui_z) { Max } else { Min }
    if context.rounding == MinMag || context.rounding == directed_rounding {
      ui_z = ui_z - 1
    } else if context.rounding == Odd {
      ui_z = (ui_z - 1) | 1
    }
  }
  {
    value: F16::from_bits(ui_z),
    context: context.raise_flags(ExceptionFlags::inexact()),
  }
}

///|
fn f16_propagate_nan_result(
  context : Context,
  ui_a : UInt16,
  ui_b : UInt16,
) -> SoftResult[F16] {
  let propagated = propagate_nan_f16_ui(context, ui_a, ui_b)
  { value: F16::from_bits(propagated.value), context: propagated.context }
}

///|
fn f16_propagate_nan3_result(
  context : Context,
  ui_a : UInt16,
  ui_b : UInt16,
  ui_c : UInt16,
) -> SoftResult[F16] {
  let ab = propagate_nan_f16_ui(context, ui_a, ui_b)
  let abc = propagate_nan_f16_ui(ab.context, ab.value, ui_c)
  { value: F16::from_bits(abc.value), context: abc.context }
}

///|
fn f16_add_mags(
  context : Context,
  ui_a : UInt16,
  ui_b : UInt16,
) -> SoftResult[F16] {
  let exp_a = exp_f16_ui(ui_a)
  let sig_a = frac_f16_ui(ui_a).to_uint()
  let exp_b = exp_f16_ui(ui_b)
  let sig_b = frac_f16_ui(ui_b).to_uint()
  let exp_diff = exp_a - exp_b
  if exp_diff == 0 {
    if exp_a == 0 {
      { value: F16::from_bits(ui_a + frac_f16_ui(ui_b)), context }
    } else if exp_a == 0x1F {
      if (sig_a | sig_b) != 0U {
        f16_propagate_nan_result(context, ui_a, ui_b)
      } else {
        { value: F16::from_bits(ui_a), context }
      }
    } else {
      let sign_z = sign_f16_ui(ui_a)
      let exp_z = exp_a
      let mut sig_z = 0x0800U + sig_a + sig_b
      if (sig_z & 1U) == 0U && exp_z < 0x1E {
        sig_z = sig_z >> 1
        {
          value: F16::from_bits(
            pack_to_f16_ui(sign_z, exp_z, sig_z.to_uint16()),
          ),
          context,
        }
      } else {
        round_pack_to_f16(context, sign_z, exp_z, sig_z << 3)
      }
    }
  } else {
    let sign_z = sign_f16_ui(ui_a)
    let mut exp_z = 0
    let mut sig_x = 0U
    let mut sig_y = 0U
    let mut shift_dist = 0
    if exp_diff < 0 {
      if exp_b == 0x1F {
        if sig_b != 0U {
          return f16_propagate_nan_result(context, ui_a, ui_b)
        }
        return {
          value: F16::from_bits(pack_to_f16_ui(sign_z, 0x1F, 0)),
          context,
        }
      }
      if exp_diff <= -13 {
        let ui_z = pack_to_f16_ui(sign_z, exp_b, sig_b.to_uint16())
        if exp_a != 0 || sig_a != 0U {
          return f16_add_epsilon(context, ui_z)
        }
        return { value: F16::from_bits(ui_z), context }
      }
      exp_z = exp_b
      sig_x = sig_b | 0x0400U
      sig_y = sig_a + (if exp_a != 0 { 0x0400U } else { sig_a })
      shift_dist = 19 + exp_diff
    } else {
      let ui_z = ui_a
      if exp_a == 0x1F {
        if sig_a != 0U {
          return f16_propagate_nan_result(context, ui_a, ui_b)
        }
        return { value: F16::from_bits(ui_z), context }
      }
      if exp_diff >= 13 {
        if exp_b != 0 || sig_b != 0U {
          return f16_add_epsilon(context, ui_z)
        }
        return { value: F16::from_bits(ui_z), context }
      }
      exp_z = exp_a
      sig_x = sig_a | 0x0400U
      sig_y = sig_b + (if exp_b != 0 { 0x0400U } else { sig_b })
      shift_dist = 19 - exp_diff
    }
    let mut sig32_z = (sig_x << 19) + (sig_y << shift_dist)
    if sig32_z < 0x40000000U {
      exp_z = exp_z - 1
      sig32_z = sig32_z << 1
    }
    let mut sig_z = sig32_z >> 16
    if (sig32_z & 0xFFFFU) != 0U {
      sig_z = sig_z | 1U
      round_pack_to_f16(context, sign_z, exp_z, sig_z)
    } else if (sig_z & 0xFU) == 0U && exp_z < 0x1E {
      sig_z = sig_z >> 4
      {
        value: F16::from_bits(pack_to_f16_ui(sign_z, exp_z, sig_z.to_uint16())),
        context,
      }
    } else {
      round_pack_to_f16(context, sign_z, exp_z, sig_z)
    }
  }
}

///|
fn f16_sub_mags(
  context : Context,
  ui_a : UInt16,
  ui_b : UInt16,
) -> SoftResult[F16] {
  let mut exp_a = exp_f16_ui(ui_a)
  let sig_a = frac_f16_ui(ui_a).to_uint()
  let exp_b = exp_f16_ui(ui_b)
  let sig_b = frac_f16_ui(ui_b).to_uint()
  let mut exp_diff = exp_a - exp_b
  if exp_diff == 0 {
    if exp_a == 0x1F {
      if (sig_a | sig_b) != 0U {
        f16_propagate_nan_result(context, ui_a, ui_b)
      } else {
        {
          value: F16::from_bits(default_nan_f16_ui(context.specialization)),
          context: context.raise_flags(ExceptionFlags::invalid()),
        }
      }
    } else {
      let mut sig_diff = sig_a.reinterpret_as_int() - sig_b.reinterpret_as_int()
      if sig_diff == 0 {
        {
          value: F16::from_bits(pack_to_f16_ui(context.rounding == Min, 0, 0)),
          context,
        }
      } else {
        if exp_a != 0 {
          exp_a = exp_a - 1
        }
        let mut sign_z = sign_f16_ui(ui_a)
        if sig_diff < 0 {
          sign_z = !sign_z
          sig_diff = -sig_diff
        }
        let mut shift_dist = count_leading_zeros16(sig_diff.to_uint16()) - 5
        let mut exp_z = exp_a - shift_dist
        if exp_z < 0 {
          shift_dist = exp_a
          exp_z = 0
        }
        let sig_z = sig_diff.reinterpret_as_uint() << shift_dist
        {
          value: F16::from_bits(
            pack_to_f16_ui(sign_z, exp_z, sig_z.to_uint16()),
          ),
          context,
        }
      }
    }
  } else {
    let mut sign_z = sign_f16_ui(ui_a)
    let mut exp_z = 0
    let mut sig_x = 0U
    let mut sig_y = 0U
    if exp_diff < 0 {
      sign_z = !sign_z
      if exp_b == 0x1F {
        if sig_b != 0U {
          return f16_propagate_nan_result(context, ui_a, ui_b)
        }
        return {
          value: F16::from_bits(pack_to_f16_ui(sign_z, 0x1F, 0)),
          context,
        }
      }
      if exp_diff <= -13 {
        let ui_z = pack_to_f16_ui(sign_z, exp_b, sig_b.to_uint16())
        if exp_a != 0 || sig_a != 0U {
          return f16_sub_epsilon(context, ui_z)
        }
        return { value: F16::from_bits(ui_z), context }
      }
      exp_z = exp_a + 19
      sig_x = sig_b | 0x0400U
      sig_y = sig_a + (if exp_a != 0 { 0x0400U } else { sig_a })
      exp_diff = -exp_diff
    } else {
      let ui_z = ui_a
      if exp_a == 0x1F {
        if sig_a != 0U {
          return f16_propagate_nan_result(context, ui_a, ui_b)
        }
        return { value: F16::from_bits(ui_z), context }
      }
      if exp_diff >= 13 {
        if exp_b != 0 || sig_b != 0U {
          return f16_sub_epsilon(context, ui_z)
        }
        return { value: F16::from_bits(ui_z), context }
      }
      exp_z = exp_b + 19
      sig_x = sig_a | 0x0400U
      sig_y = sig_b + (if exp_b != 0 { 0x0400U } else { sig_b })
    }
    let mut sig32_z = (sig_x << exp_diff) - sig_y
    let shift_dist = count_leading_zeros32(sig32_z) - 1
    sig32_z = sig32_z << shift_dist
    exp_z = exp_z - shift_dist
    let mut sig_z = sig32_z >> 16
    if (sig32_z & 0xFFFFU) != 0U {
      sig_z = sig_z | 1U
      round_pack_to_f16(context, sign_z, exp_z, sig_z)
    } else if (sig_z & 0xFU) == 0U && exp_z >= 0 && exp_z < 0x1E {
      sig_z = sig_z >> 4
      {
        value: F16::from_bits(pack_to_f16_ui(sign_z, exp_z, sig_z.to_uint16())),
        context,
      }
    } else {
      round_pack_to_f16(context, sign_z, exp_z, sig_z)
    }
  }
}

///|
/// Adds two F16 values using the rounding mode carried by `context`.
///
/// NaNs are propagated, with signaling NaNs raising `Invalid`. Adding opposite
/// infinities raises `Invalid` and returns the specialization default NaN.
/// Exact cancellation returns `+0` except under round-min, which returns `-0`.
/// Finite inexact results may raise `Inexact`, `Underflow`, or
/// `Overflow | Inexact`.
pub fn F16::add(self : F16, context : Context, rhs : F16) -> SoftResult[F16] {
  f16_add(context, self, rhs)
}

///|
/// Subtracts two F16 values using the rounding mode carried by `context`.
///
/// This has the same boundary behavior as `f16_sub`: NaNs propagate,
/// signaling NaNs raise `Invalid`, subtracting equal-signed infinities raises
/// `Invalid`, and exact finite cancellation returns a signed zero selected by
/// the rounding mode.
pub fn F16::sub(self : F16, context : Context, rhs : F16) -> SoftResult[F16] {
  f16_sub(context, self, rhs)
}

///|
/// Function-style F16 addition wrapper for the SoftFloat C symbol.
///
/// Equivalent to `a.add(context, b)`, including NaN, infinity, signed-zero, and
/// rounding flag behavior.
pub fn f16_add(context : Context, a : F16, b : F16) -> SoftResult[F16] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  if sign_f16_ui(ui_a) != sign_f16_ui(ui_b) {
    f16_sub_mags(context, ui_a, ui_b)
  } else {
    f16_add_mags(context, ui_a, ui_b)
  }
}

///|
/// Function-style F16 subtraction wrapper for the SoftFloat C symbol.
///
/// Equivalent to `a.sub(context, b)`.
pub fn f16_sub(context : Context, a : F16, b : F16) -> SoftResult[F16] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  if sign_f16_ui(ui_a) != sign_f16_ui(ui_b) {
    f16_add_mags(context, ui_a, ui_b)
  } else {
    f16_sub_mags(context, ui_a, ui_b)
  }
}

///|
/// Multiplies two F16 values using the rounding mode carried by `context`.
///
/// NaNs propagate, with signaling NaNs raising `Invalid`. Multiplying zero by
/// infinity raises `Invalid` and returns the specialization default NaN.
/// Otherwise infinities and zeros keep the XOR of operand signs. Finite
/// products are rounded in the supplied context and may raise the usual
/// inexact, underflow, or overflow flags.
pub fn F16::mul(self : F16, context : Context, rhs : F16) -> SoftResult[F16] {
  f16_mul(context, self, rhs)
}

///|
/// Function-style F16 multiplication wrapper for the SoftFloat C symbol.
///
/// Equivalent to `a.mul(context, b)`.
pub fn f16_mul(context : Context, a : F16, b : F16) -> SoftResult[F16] {
  let ui_a = a.to_bits()
  let sign_a = sign_f16_ui(ui_a)
  let mut exp_a = exp_f16_ui(ui_a)
  let mut sig_a = frac_f16_ui(ui_a).to_uint()
  let ui_b = b.to_bits()
  let sign_b = sign_f16_ui(ui_b)
  let mut exp_b = exp_f16_ui(ui_b)
  let mut sig_b = frac_f16_ui(ui_b).to_uint()
  let sign_z = sign_a != sign_b
  if exp_a == 0x1F {
    if sig_a != 0U || (exp_b == 0x1F && sig_b != 0U) {
      return f16_propagate_nan_result(context, ui_a, ui_b)
    }
    if exp_b == 0 && sig_b == 0U {
      return {
        value: F16::from_bits(default_nan_f16_ui(context.specialization)),
        context: context.raise_flags(ExceptionFlags::invalid()),
      }
    }
    return { value: F16::from_bits(pack_to_f16_ui(sign_z, 0x1F, 0)), context }
  }
  if exp_b == 0x1F {
    if sig_b != 0U {
      return f16_propagate_nan_result(context, ui_a, ui_b)
    }
    if exp_a == 0 && sig_a == 0U {
      return {
        value: F16::from_bits(default_nan_f16_ui(context.specialization)),
        context: context.raise_flags(ExceptionFlags::invalid()),
      }
    }
    return { value: F16::from_bits(pack_to_f16_ui(sign_z, 0x1F, 0)), context }
  }
  if exp_a == 0 {
    if sig_a == 0U {
      return { value: F16::from_bits(pack_to_f16_ui(sign_z, 0, 0)), context }
    }
    let norm = norm_subnormal_f16_sig(sig_a.to_uint16())
    exp_a = norm.exp
    sig_a = norm.sig.to_uint()
  }
  if exp_b == 0 {
    if sig_b == 0U {
      return { value: F16::from_bits(pack_to_f16_ui(sign_z, 0, 0)), context }
    }
    let norm = norm_subnormal_f16_sig(sig_b.to_uint16())
    exp_b = norm.exp
    sig_b = norm.sig.to_uint()
  }
  let mut exp_z = exp_a + exp_b - 0x0F
  sig_a = (sig_a | 0x0400U) << 4
  sig_b = (sig_b | 0x0400U) << 5
  let sig32_z = sig_a * sig_b
  let mut sig_z = sig32_z >> 16
  if (sig32_z & 0xFFFFU) != 0U {
    sig_z = sig_z | 1U
  }
  if sig_z < 0x4000U {
    exp_z = exp_z - 1
    sig_z = sig_z << 1
  }
  round_pack_to_f16(context, sign_z, exp_z, sig_z)
}

///|
/// Divides two F16 values using the rounding mode carried by `context`.
///
/// NaNs propagate. `infinity / infinity` and `0 / 0` raise `Invalid` and
/// return the specialization default NaN. A finite nonzero dividend divided by
/// zero raises `Infinite` and returns a signed infinity. A finite value divided
/// by infinity returns signed zero.
pub fn F16::div(self : F16, context : Context, rhs : F16) -> SoftResult[F16] {
  f16_div(context, self, rhs)
}

///|
/// Function-style F16 division wrapper for the SoftFloat C symbol.
///
/// Equivalent to `a.div(context, b)`.
pub fn f16_div(context : Context, a : F16, b : F16) -> SoftResult[F16] {
  let ui_a = a.to_bits()
  let sign_a = sign_f16_ui(ui_a)
  let mut exp_a = exp_f16_ui(ui_a)
  let mut sig_a = frac_f16_ui(ui_a).to_uint()
  let ui_b = b.to_bits()
  let sign_b = sign_f16_ui(ui_b)
  let mut exp_b = exp_f16_ui(ui_b)
  let mut sig_b = frac_f16_ui(ui_b).to_uint()
  let sign_z = sign_a != sign_b
  if exp_a == 0x1F {
    if sig_a != 0U {
      return f16_propagate_nan_result(context, ui_a, ui_b)
    }
    if exp_b == 0x1F {
      if sig_b != 0U {
        return f16_propagate_nan_result(context, ui_a, ui_b)
      }
      return {
        value: F16::from_bits(default_nan_f16_ui(context.specialization)),
        context: context.raise_flags(ExceptionFlags::invalid()),
      }
    }
    return { value: F16::from_bits(pack_to_f16_ui(sign_z, 0x1F, 0)), context }
  }
  if exp_b == 0x1F {
    if sig_b != 0U {
      return f16_propagate_nan_result(context, ui_a, ui_b)
    }
    return { value: F16::from_bits(pack_to_f16_ui(sign_z, 0, 0)), context }
  }
  if exp_b == 0 {
    if sig_b == 0U {
      if exp_a == 0 && sig_a == 0U {
        return {
          value: F16::from_bits(default_nan_f16_ui(context.specialization)),
          context: context.raise_flags(ExceptionFlags::invalid()),
        }
      }
      return {
        value: F16::from_bits(pack_to_f16_ui(sign_z, 0x1F, 0)),
        context: context.raise_flags(ExceptionFlags::infinite()),
      }
    }
    let norm = norm_subnormal_f16_sig(sig_b.to_uint16())
    exp_b = norm.exp
    sig_b = norm.sig.to_uint()
  }
  if exp_a == 0 {
    if sig_a == 0U {
      return { value: F16::from_bits(pack_to_f16_ui(sign_z, 0, 0)), context }
    }
    let norm = norm_subnormal_f16_sig(sig_a.to_uint16())
    exp_a = norm.exp
    sig_a = norm.sig.to_uint()
  }
  let mut exp_z = exp_a - exp_b + 0x0E
  sig_a = sig_a | 0x0400U
  sig_b = sig_b | 0x0400U
  if sig_a < sig_b {
    exp_z = exp_z - 1
    sig_a = sig_a << 5
  } else {
    sig_a = sig_a << 4
  }
  let index = ((sig_b >> 6) & 0xFU).reinterpret_as_int()
  let r0 = approx_recip_1k0(index) -
    ((approx_recip_1k1(index) * (sig_b & 0x3FU).to_uint64()) >> 10)
  let mut sig_z = ((sig_a.to_uint64() * r0) >> 16).to_uint()
  let mut rem = ((sig_a << 10) - sig_z * sig_b) & 0xFFFFU
  sig_z = sig_z + ((rem.to_uint64() * r0) >> 26).to_uint()
  sig_z = sig_z + 1
  if (sig_z & 7U) == 0U {
    sig_z = sig_z & 0xFFFFFFFEU
    rem = ((sig_a << 10) - sig_z * sig_b) & 0xFFFFU
    if (rem & 0x8000U) != 0U {
      sig_z = sig_z - 2
    } else if rem != 0U {
      sig_z = sig_z | 1U
    }
  }
  round_pack_to_f16(context, sign_z, exp_z, sig_z)
}

///|
/// Computes the F16 square root using the rounding mode carried by `context`.
///
/// NaNs propagate. `+infinity` and both signed zeros are returned unchanged.
/// Negative nonzero finite values and `-infinity` raise `Invalid` and return
/// the specialization default NaN. Inexact finite roots may raise `Inexact`.
pub fn F16::sqrt(self : F16, context : Context) -> SoftResult[F16] {
  f16_sqrt(context, self)
}

///|
/// Function-style F16 square-root wrapper for the SoftFloat C symbol.
///
/// Equivalent to `a.sqrt(context)`.
pub fn f16_sqrt(context : Context, a : F16) -> SoftResult[F16] {
  let ui_a = a.to_bits()
  let sign_a = sign_f16_ui(ui_a)
  let mut exp_a = exp_f16_ui(ui_a)
  let mut sig_a = frac_f16_ui(ui_a).to_uint()
  if exp_a == 0x1F {
    if sig_a != 0U {
      return f16_propagate_nan_result(context, ui_a, 0)
    }
    if !sign_a {
      return { value: a, context }
    }
    return {
      value: F16::from_bits(default_nan_f16_ui(context.specialization)),
      context: context.raise_flags(ExceptionFlags::invalid()),
    }
  }
  if sign_a {
    if exp_a == 0 && sig_a == 0U {
      return { value: a, context }
    }
    return {
      value: F16::from_bits(default_nan_f16_ui(context.specialization)),
      context: context.raise_flags(ExceptionFlags::invalid()),
    }
  }
  if exp_a == 0 {
    if sig_a == 0U {
      return { value: a, context }
    }
    let norm = norm_subnormal_f16_sig(sig_a.to_uint16())
    exp_a = norm.exp
    sig_a = norm.sig.to_uint()
  }
  let exp_a_lsb = if exp_a / 2 * 2 == exp_a { 0 } else { 1 }
  let exp_z = ((exp_a - 0x0F) >> 1) + 0x0E
  sig_a = sig_a | 0x0400U
  let index = ((sig_a >> 6) & 0xEU).reinterpret_as_int() + exp_a_lsb
  let r0 = approx_recip_sqrt_1k0(index) -
    ((approx_recip_sqrt_1k1(index) * (sig_a & 0x7FU).to_uint64()) >> 11)
  let mut e_sqr_r0 = (r0 * r0) >> 1
  if exp_a_lsb != 0 {
    e_sqr_r0 = e_sqr_r0 >> 1
  }
  let sigma0 = 0xFFFFU -
    (((e_sqr_r0 * sig_a.to_uint64()) >> 16).to_uint() & 0xFFFFU)
  let mut recip_sqrt16 = (r0 + ((r0 * sigma0.to_uint64()) >> 25)).to_uint()
  if (recip_sqrt16 & 0x8000U) == 0U {
    recip_sqrt16 = 0x8000U
  }
  let mut sig_z = (((sig_a << 5).to_uint64() * recip_sqrt16.to_uint64()) >> 16).to_uint()
  if exp_a_lsb != 0 {
    sig_z = sig_z >> 1
  }
  sig_z = sig_z + 1
  if (sig_z & 7U) == 0U {
    let shifted_sig_z = sig_z >> 1
    let neg_rem = (shifted_sig_z * shifted_sig_z) & 0xFFFFU
    sig_z = sig_z & 0xFFFFFFFEU
    if (neg_rem & 0x8000U) != 0U {
      sig_z = sig_z | 1U
    } else if neg_rem != 0U {
      sig_z = sig_z - 1
    }
  }
  round_pack_to_f16(context, false, exp_z, sig_z)
}

///|
/// Computes the IEEE F16 remainder using the rounding mode carried by `context`.
///
/// NaNs propagate. An infinite dividend or zero divisor raises `Invalid`;
/// a finite dividend with an infinite divisor is returned unchanged. The
/// quotient is rounded to nearest with even-tie handling as in SoftFloat
/// `f16_rem`; the final remainder is normalized with the expected IEEE sign.
pub fn F16::rem(self : F16, context : Context, rhs : F16) -> SoftResult[F16] {
  f16_rem(context, self, rhs)
}

///|
/// Function-style F16 remainder wrapper for the SoftFloat C symbol.
///
/// Equivalent to `a.rem(context, b)`.
pub fn f16_rem(context : Context, a : F16, b : F16) -> SoftResult[F16] {
  let ui_a = a.to_bits()
  let sign_a = sign_f16_ui(ui_a)
  let mut exp_a = exp_f16_ui(ui_a)
  let mut sig_a = frac_f16_ui(ui_a).to_uint()
  let ui_b = b.to_bits()
  let mut exp_b = exp_f16_ui(ui_b)
  let mut sig_b = frac_f16_ui(ui_b).to_uint()
  if exp_a == 0x1F {
    if sig_a != 0U || (exp_b == 0x1F && sig_b != 0U) {
      return f16_propagate_nan_result(context, ui_a, ui_b)
    }
    return {
      value: F16::from_bits(default_nan_f16_ui(context.specialization)),
      context: context.raise_flags(ExceptionFlags::invalid()),
    }
  }
  if exp_b == 0x1F {
    if sig_b != 0U {
      return f16_propagate_nan_result(context, ui_a, ui_b)
    }
    return { value: a, context }
  }
  if exp_b == 0 {
    if sig_b == 0U {
      return {
        value: F16::from_bits(default_nan_f16_ui(context.specialization)),
        context: context.raise_flags(ExceptionFlags::invalid()),
      }
    }
    let norm = norm_subnormal_f16_sig(sig_b.to_uint16())
    exp_b = norm.exp
    sig_b = norm.sig.to_uint()
  }
  if exp_a == 0 {
    if sig_a == 0U {
      return { value: a, context }
    }
    let norm = norm_subnormal_f16_sig(sig_a.to_uint16())
    exp_a = norm.exp
    sig_a = norm.sig.to_uint()
  }
  let mut rem = sig_a | 0x0400U
  sig_b = sig_b | 0x0400U
  let mut exp_diff = exp_a - exp_b
  let mut q = 0U
  if exp_diff < 1 {
    if exp_diff < -1 {
      return { value: a, context }
    }
    sig_b = sig_b << 3
    if exp_diff != 0 {
      rem = (rem << 2) & 0xFFFFU
    } else {
      rem = (rem << 3) & 0xFFFFU
      if sig_b <= rem {
        q = 1U
        rem = (rem - sig_b) & 0xFFFFU
      }
    }
  } else {
    let recip32 = approx_recip32_1(sig_b << 21)
    rem = (rem << 4) & 0xFFFFU
    exp_diff = exp_diff - 31
    sig_b = sig_b << 3
    let mut q32 = 0U
    while true {
      q32 = ((rem.to_uint64() * recip32.to_uint64()) >> 16).to_uint()
      if exp_diff < 0 {
        break
      }
      rem = (0U - (q32 & 0xFFFFU) * sig_b) & 0xFFFFU
      exp_diff = exp_diff - 29
    }
    q32 = q32 >> (-exp_diff - 1)
    q = q32
    rem = ((rem << (exp_diff + 30)) - q * sig_b) & 0xFFFFU
  }
  let mut alt_rem = 0U
  while true {
    alt_rem = rem
    q = q + 1
    rem = (rem - sig_b) & 0xFFFFU
    if (rem & 0x8000U) != 0U {
      break
    }
  }
  let mean_rem = (rem + alt_rem) & 0xFFFFU
  if (mean_rem & 0x8000U) != 0U || (mean_rem == 0U && (q & 1U) != 0U) {
    rem = alt_rem
  }
  let mut sign_rem = sign_a
  if rem >= 0x8000U {
    sign_rem = !sign_rem
    rem = (0U - rem) & 0xFFFFU
  }
  norm_round_pack_to_f16(context, sign_rem, exp_b, rem)
}

///|
/// Computes fused `(self * rhs) + addend` for F16 values.
///
/// Multiplication and addition are fused with a single final rounding. NaNs
/// propagate, signaling NaNs raise `Invalid`, `0 * infinity` raises `Invalid`,
/// and an infinite product added to an opposite-signed infinity raises
/// `Invalid`. Complete cancellation returns a signed zero selected by
/// round-min versus the other rounding modes.
pub fn F16::mul_add(
  self : F16,
  context : Context,
  rhs : F16,
  addend : F16,
) -> SoftResult[F16] {
  f16_mul_add(context, self, rhs, addend)
}

///|
/// Function-style fused F16 multiply-add wrapper for `f16_mulAdd`.
///
/// Equivalent to `a.mul_add(context, b, c)`.
pub fn f16_mul_add(
  context : Context,
  a : F16,
  b : F16,
  c : F16,
) -> SoftResult[F16] {
  let ui_a = a.to_bits()
  let sign_a = sign_f16_ui(ui_a)
  let mut exp_a = exp_f16_ui(ui_a)
  let mut sig_a = frac_f16_ui(ui_a).to_uint()
  let ui_b = b.to_bits()
  let sign_b = sign_f16_ui(ui_b)
  let mut exp_b = exp_f16_ui(ui_b)
  let mut sig_b = frac_f16_ui(ui_b).to_uint()
  let ui_c = c.to_bits()
  let sign_c = sign_f16_ui(ui_c)
  let mut exp_c = exp_f16_ui(ui_c)
  let mut sig_c = frac_f16_ui(ui_c).to_uint()
  let sign_prod = sign_a != sign_b
  if exp_a == 0x1F {
    if sig_a != 0U || (exp_b == 0x1F && sig_b != 0U) {
      return f16_propagate_nan3_result(context, ui_a, ui_b, ui_c)
    }
    return f16_mul_add_inf_prod(
      context, sign_prod, exp_b, sig_b, sign_c, exp_c, sig_c, ui_c,
    )
  }
  if exp_b == 0x1F {
    if sig_b != 0U {
      return f16_propagate_nan3_result(context, ui_a, ui_b, ui_c)
    }
    return f16_mul_add_inf_prod(
      context, sign_prod, exp_a, sig_a, sign_c, exp_c, sig_c, ui_c,
    )
  }
  if exp_c == 0x1F {
    if sig_c != 0U {
      return f16_propagate_nan_result(context, 0, ui_c)
    }
    return { value: c, context }
  }
  if exp_a == 0 {
    if sig_a == 0U {
      return f16_mul_add_zero_prod(
        context, sign_prod, sign_c, exp_c, sig_c, ui_c,
      )
    }
    let norm = norm_subnormal_f16_sig(sig_a.to_uint16())
    exp_a = norm.exp
    sig_a = norm.sig.to_uint()
  }
  if exp_b == 0 {
    if sig_b == 0U {
      return f16_mul_add_zero_prod(
        context, sign_prod, sign_c, exp_c, sig_c, ui_c,
      )
    }
    let norm = norm_subnormal_f16_sig(sig_b.to_uint16())
    exp_b = norm.exp
    sig_b = norm.sig.to_uint()
  }
  let mut exp_prod = exp_a + exp_b - 0x0E
  sig_a = (sig_a | 0x0400U) << 4
  sig_b = (sig_b | 0x0400U) << 4
  let mut sig_prod = sig_a * sig_b
  if sig_prod < 0x20000000U {
    exp_prod = exp_prod - 1
    sig_prod = sig_prod << 1
  }
  let mut sign_z = sign_prod
  if exp_c == 0 {
    if sig_c == 0U {
      let exp_z = exp_prod - 1
      let sig_z = (sig_prod >> 15) |
        (if (sig_prod & 0x7FFFU) != 0U { 1U } else { 0U })
      return round_pack_to_f16(context, sign_z, exp_z, sig_z)
    }
    let norm = norm_subnormal_f16_sig(sig_c.to_uint16())
    exp_c = norm.exp
    sig_c = norm.sig.to_uint()
  }
  sig_c = (sig_c | 0x0400U) << 3
  let exp_diff = exp_prod - exp_c
  let mut exp_z = 0
  let mut sig_z = 0U
  if sign_prod == sign_c {
    if exp_diff <= 0 {
      exp_z = exp_c
      sig_z = sig_c + shift_right_jam32(sig_prod, 16 - exp_diff)
    } else {
      exp_z = exp_prod
      let sig32_z = sig_prod + shift_right_jam32(sig_c << 16, exp_diff)
      sig_z = (sig32_z >> 16) |
        (if (sig32_z & 0xFFFFU) != 0U { 1U } else { 0U })
    }
    if sig_z < 0x4000U {
      exp_z = exp_z - 1
      sig_z = sig_z << 1
    }
  } else {
    let sig32_c = sig_c << 16
    let mut sig32_z = 0U
    if exp_diff < 0 {
      sign_z = sign_c
      exp_z = exp_c
      sig32_z = sig32_c - shift_right_jam32(sig_prod, -exp_diff)
    } else if exp_diff == 0 {
      exp_z = exp_prod
      sig32_z = sig_prod - sig32_c
      if sig32_z == 0U {
        return {
          value: F16::from_bits(pack_to_f16_ui(context.rounding == Min, 0, 0)),
          context,
        }
      }
      if (sig32_z & 0x80000000U) != 0U {
        sign_z = !sign_z
        sig32_z = 0U - sig32_z
      }
    } else {
      exp_z = exp_prod
      sig32_z = sig_prod - shift_right_jam32(sig32_c, exp_diff)
    }
    let mut shift_dist = count_leading_zeros32(sig32_z) - 1
    exp_z = exp_z - shift_dist
    shift_dist = shift_dist - 16
    if shift_dist < 0 {
      sig_z = shift_right_jam32(sig32_z, -shift_dist)
    } else {
      sig_z = sig32_z << shift_dist
    }
  }
  round_pack_to_f16(context, sign_z, exp_z, sig_z)
}

///|
fn f16_mul_add_inf_prod(
  context : Context,
  sign_prod : Bool,
  exp_mag : Int,
  sig_mag : UInt,
  sign_c : Bool,
  exp_c : Int,
  sig_c : UInt,
  ui_c : UInt16,
) -> SoftResult[F16] {
  if exp_mag != 0 || sig_mag != 0U {
    let ui_z = pack_to_f16_ui(sign_prod, 0x1F, 0)
    if exp_c != 0x1F {
      return { value: F16::from_bits(ui_z), context }
    }
    if sig_c != 0U {
      return f16_propagate_nan_result(context, ui_z, ui_c)
    }
    if sign_prod == sign_c {
      return { value: F16::from_bits(ui_z), context }
    }
  }
  let invalid_context = context.raise_flags(ExceptionFlags::invalid())
  f16_propagate_nan_result(
    invalid_context,
    default_nan_f16_ui(context.specialization),
    ui_c,
  )
}

///|
fn f16_mul_add_zero_prod(
  context : Context,
  sign_prod : Bool,
  sign_c : Bool,
  exp_c : Int,
  sig_c : UInt,
  ui_c : UInt16,
) -> SoftResult[F16] {
  if exp_c == 0 && sig_c == 0U && sign_prod != sign_c {
    {
      value: F16::from_bits(pack_to_f16_ui(context.rounding == Min, 0, 0)),
      context,
    }
  } else {
    { value: F16::from_bits(ui_c), context }
  }
}

///|
fn f16_both_zero(a : UInt16, b : UInt16) -> Bool {
  (((a | b) << 1) & 0xFFFF) == 0
}

///|
fn f16_ordered_le(a : UInt16, b : UInt16) -> Bool {
  let sign_a = sign_f16_ui(a)
  let sign_b = sign_f16_ui(b)
  if sign_a != sign_b {
    sign_a || f16_both_zero(a, b)
  } else {
    a == b || sign_a != (a < b)
  }
}

///|
fn f16_ordered_lt(a : UInt16, b : UInt16) -> Bool {
  let sign_a = sign_f16_ui(a)
  let sign_b = sign_f16_ui(b)
  if sign_a != sign_b {
    sign_a && !f16_both_zero(a, b)
  } else {
    a != b && sign_a != (a < b)
  }
}

///|
fn f16_compare_nan_context(
  context : Context,
  a : UInt16,
  b : UInt16,
  quiet : Bool,
) -> Context {
  if is_nan_f16_ui(a) || is_nan_f16_ui(b) {
    if !quiet || is_sig_nan_f16_ui(a) || is_sig_nan_f16_ui(b) {
      context.raise_flags(ExceptionFlags::invalid())
    } else {
      context
    }
  } else {
    context
  }
}

///|
/// Implements SoftFloat `f16_eq`.
///
/// Quiet NaNs compare false without raising flags; signaling NaNs raise
/// `Invalid` and compare false. `+0` and `-0` compare equal.
pub fn f16_eq(context : Context, a : F16, b : F16) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  let context = f16_compare_nan_context(context, ui_a, ui_b, true)
  if is_nan_f16_ui(ui_a) || is_nan_f16_ui(ui_b) {
    { value: false, context }
  } else {
    { value: ui_a == ui_b || f16_both_zero(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f16_eq_signaling`.
///
/// Any NaN operand raises `Invalid` and compares false. `+0` and `-0` compare
/// equal.
pub fn f16_eq_signaling(
  context : Context,
  a : F16,
  b : F16,
) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  let context = f16_compare_nan_context(context, ui_a, ui_b, false)
  if is_nan_f16_ui(ui_a) || is_nan_f16_ui(ui_b) {
    { value: false, context }
  } else {
    { value: ui_a == ui_b || f16_both_zero(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f16_le`.
///
/// Any NaN operand raises `Invalid` and returns false. Signed zeros compare
/// equal, so both `+0 <= -0` and `-0 <= +0` are true.
pub fn f16_le(context : Context, a : F16, b : F16) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  if is_nan_f16_ui(ui_a) || is_nan_f16_ui(ui_b) {
    { value: false, context: context.raise_flags(ExceptionFlags::invalid()) }
  } else {
    { value: f16_ordered_le(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f16_lt`.
///
/// Any NaN operand raises `Invalid` and returns false. Signed zeros compare
/// equal, so neither zero is less than the other.
pub fn f16_lt(context : Context, a : F16, b : F16) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  if is_nan_f16_ui(ui_a) || is_nan_f16_ui(ui_b) {
    { value: false, context: context.raise_flags(ExceptionFlags::invalid()) }
  } else {
    { value: f16_ordered_lt(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f16_le_quiet`.
///
/// Quiet NaNs return false without flags; signaling NaNs raise `Invalid`.
/// Signed zeros compare equal.
pub fn f16_le_quiet(context : Context, a : F16, b : F16) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  let context = f16_compare_nan_context(context, ui_a, ui_b, true)
  if is_nan_f16_ui(ui_a) || is_nan_f16_ui(ui_b) {
    { value: false, context }
  } else {
    { value: f16_ordered_le(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f16_lt_quiet`.
///
/// Quiet NaNs return false without flags; signaling NaNs raise `Invalid`.
/// Signed zeros compare equal, so zero-vs-zero is never less-than.
pub fn f16_lt_quiet(context : Context, a : F16, b : F16) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  let context = f16_compare_nan_context(context, ui_a, ui_b, true)
  if is_nan_f16_ui(ui_a) || is_nan_f16_ui(ui_b) {
    { value: false, context }
  } else {
    { value: f16_ordered_lt(ui_a, ui_b), context }
  }
}
