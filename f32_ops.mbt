///|
/// Converts F32 to F16 with SoftFloat NaN, overflow, and subnormal handling.
///
/// Signed zeros and infinities keep their sign. Finite values are rounded to
/// binary16 according to the context and may raise `Inexact`, `Underflow`, or
/// `Overflow | Inexact`; overflow returns infinity or the largest finite F16
/// as SoftFloat specifies. NaNs use specialization-specific propagation, and
/// signaling NaNs raise `Invalid`.
pub fn F32::to_f16(self : F32, context : Context) -> SoftResult[F16] {
  let bits = self.to_bits()
  let sign = sign_f32_ui(bits)
  let exp = exp_f32_ui(bits)
  let frac = frac_f32_ui(bits)
  if exp == 0xFF {
    if frac != 0U {
      let common = f32_ui_to_common_nan(context, bits)
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
    let frac16 = (frac >> 9) | (if (frac & 0x1FFU) != 0U { 1U } else { 0U })
    if (exp.reinterpret_as_uint() | frac16) == 0U {
      { value: F16::from_bits(pack_to_f16_ui(sign, 0, 0)), context }
    } else {
      round_pack_to_f16(context, sign, exp - 0x71, frac16 | 0x4000U)
    }
  }
}

///|
/// Converts F32 to F64 exactly for finite inputs.
///
/// Signed zeros, subnormals, normals, and infinities are widened without
/// rounding. NaNs are converted through the selected specialization; signaling
/// NaNs raise `Invalid`.
pub fn F32::to_f64(self : F32, context : Context) -> SoftResult[F64] {
  let bits = self.to_bits()
  let sign = sign_f32_ui(bits)
  let mut exp = exp_f32_ui(bits)
  let mut frac = frac_f32_ui(bits)
  if exp == 0xFF {
    if frac != 0U {
      let common = f32_ui_to_common_nan(context, bits)
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
      if frac == 0U {
        return { value: F64::from_bits(pack_to_f64_ui(sign, 0, 0UL)), context }
      }
      let norm = norm_subnormal_f32_sig(frac)
      exp = norm.exp - 1
      frac = norm.sig
    }
    {
      value: F64::from_bits(
        pack_to_f64_ui(sign, exp + 0x380, frac.to_uint64() << 29),
      ),
      context,
    }
  }
}

///|
/// Function-style wrapper for SoftFloat `f32_to_f16`.
///
/// Equivalent to `a.to_f16(context)`.
pub fn f32_to_f16(context : Context, a : F32) -> SoftResult[F16] {
  a.to_f16(context)
}

///|
/// Function-style wrapper for SoftFloat `f32_to_f64`.
///
/// Equivalent to `a.to_f64(context)`.
pub fn f32_to_f64(context : Context, a : F32) -> SoftResult[F64] {
  a.to_f64(context)
}

///|
/// Function-style F32 signaling-NaN predicate wrapper.
///
/// Equivalent to `a.is_signaling_nan()` and raises no flags.
pub fn f32_is_signaling_nan(a : F32) -> Bool {
  a.is_signaling_nan()
}

///|
fn f32_propagate_nan_result(
  context : Context,
  ui_a : UInt,
  ui_b : UInt,
) -> SoftResult[F32] {
  let propagated = propagate_nan_f32_ui(context, ui_a, ui_b)
  { value: F32::from_bits(propagated.value), context: propagated.context }
}

///|
fn f32_propagate_nan3_result(
  context : Context,
  ui_a : UInt,
  ui_b : UInt,
  ui_c : UInt,
) -> SoftResult[F32] {
  let ab = propagate_nan_f32_ui(context, ui_a, ui_b)
  let abc = propagate_nan_f32_ui(ab.context, ab.value, ui_c)
  { value: F32::from_bits(abc.value), context: abc.context }
}

///|
/// Rounds F32 to an integral F32 value with operation-local rounding.
///
/// `exact` controls whether changed finite inputs raise `Inexact`; NaNs are
/// propagated according to `context.specialization`. Infinities and already
/// integral finite values are returned unchanged. Values with magnitude below
/// 1 round to signed zero or signed one according to `rounding`; no overflow or
/// underflow flag is raised.
pub fn F32::round_to_int(
  self : F32,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[F32] {
  let ui_a = self.to_bits()
  let exp = exp_f32_ui(ui_a)
  if exp <= 0x7E {
    if ui_a << 1 == 0U {
      return { value: self, context }
    }
    let mut context = context
    if exact {
      context = context.raise_flags(ExceptionFlags::inexact())
    }
    let mut ui_z = ui_a & pack_to_f32_ui(true, 0, 0U)
    match rounding {
      NearEven =>
        if frac_f32_ui(ui_a) != 0U && exp == 0x7E {
          ui_z = ui_z | pack_to_f32_ui(false, 0x7F, 0U)
        }
      NearMaxMag =>
        if exp == 0x7E {
          ui_z = ui_z | pack_to_f32_ui(false, 0x7F, 0U)
        }
      Min => if ui_z != 0U { ui_z = pack_to_f32_ui(true, 0x7F, 0U) }
      Max => if ui_z == 0U { ui_z = pack_to_f32_ui(false, 0x7F, 0U) }
      Odd => ui_z = ui_z | pack_to_f32_ui(false, 0x7F, 0U)
      MinMag => ()
    }
    { value: F32::from_bits(ui_z), context }
  } else if exp >= 0x96 {
    if exp == 0xFF && frac_f32_ui(ui_a) != 0U {
      f32_propagate_nan_result(context, ui_a, 0U)
    } else {
      { value: self, context }
    }
  } else {
    let mut ui_z = ui_a
    let last_bit_mask = 1U << (0x96 - exp)
    let round_bits_mask = last_bit_mask - 1U
    let directed_rounding = if sign_f32_ui(ui_z) { Min } else { Max }
    if rounding == NearMaxMag {
      ui_z = ui_z + (last_bit_mask >> 1)
    } else if rounding == NearEven {
      ui_z = ui_z + (last_bit_mask >> 1)
      if (ui_z & round_bits_mask) == 0U {
        ui_z = ui_z & (0xFFFFFFFFU - last_bit_mask)
      }
    } else if rounding == directed_rounding {
      ui_z = ui_z + round_bits_mask
    }
    ui_z = ui_z & (0xFFFFFFFFU - round_bits_mask)
    let mut context = context
    if ui_z != ui_a {
      if rounding == Odd {
        ui_z = ui_z | last_bit_mask
      }
      if exact {
        context = context.raise_flags(ExceptionFlags::inexact())
      }
    }
    { value: F32::from_bits(ui_z), context }
  }
}

///|
/// Function-style F32 round-to-integral wrapper for `f32_roundToInt`.
///
/// Equivalent to `a.round_to_int(context, rounding, exact)`.
pub fn f32_round_to_int(
  context : Context,
  a : F32,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[F32] {
  a.round_to_int(context, rounding, exact)
}

///|
fn f32_add_mags(context : Context, ui_a : UInt, ui_b : UInt) -> SoftResult[F32] {
  let exp_a = exp_f32_ui(ui_a)
  let mut sig_a = frac_f32_ui(ui_a)
  let exp_b = exp_f32_ui(ui_b)
  let mut sig_b = frac_f32_ui(ui_b)
  let exp_diff = exp_a - exp_b
  if exp_diff == 0 {
    if exp_a == 0 {
      { value: F32::from_bits(ui_a + sig_b), context }
    } else if exp_a == 0xFF {
      if (sig_a | sig_b) != 0U {
        f32_propagate_nan_result(context, ui_a, ui_b)
      } else {
        { value: F32::from_bits(ui_a), context }
      }
    } else {
      let sign_z = sign_f32_ui(ui_a)
      let exp_z = exp_a
      let mut sig_z = 0x01000000U + sig_a + sig_b
      if (sig_z & 1U) == 0U && exp_z < 0xFE {
        {
          value: F32::from_bits(pack_to_f32_ui(sign_z, exp_z, sig_z >> 1)),
          context,
        }
      } else {
        sig_z = sig_z << 6
        round_pack_to_f32(context, sign_z, exp_z, sig_z)
      }
    }
  } else {
    let sign_z = sign_f32_ui(ui_a)
    sig_a = sig_a << 6
    sig_b = sig_b << 6
    let mut exp_z = 0
    if exp_diff < 0 {
      if exp_b == 0xFF {
        if sig_b != 0U {
          return f32_propagate_nan_result(context, ui_a, ui_b)
        }
        return {
          value: F32::from_bits(pack_to_f32_ui(sign_z, 0xFF, 0U)),
          context,
        }
      }
      exp_z = exp_b
      sig_a = sig_a + (if exp_a != 0 { 0x20000000U } else { sig_a })
      sig_a = shift_right_jam32(sig_a, -exp_diff)
    } else {
      if exp_a == 0xFF {
        if sig_a != 0U {
          return f32_propagate_nan_result(context, ui_a, ui_b)
        }
        return { value: F32::from_bits(ui_a), context }
      }
      exp_z = exp_a
      sig_b = sig_b + (if exp_b != 0 { 0x20000000U } else { sig_b })
      sig_b = shift_right_jam32(sig_b, exp_diff)
    }
    let mut sig_z = 0x20000000U + sig_a + sig_b
    let mut exp_z = exp_z
    if sig_z < 0x40000000U {
      exp_z = exp_z - 1
      sig_z = sig_z << 1
    }
    round_pack_to_f32(context, sign_z, exp_z, sig_z)
  }
}

///|
fn f32_sub_mags(context : Context, ui_a : UInt, ui_b : UInt) -> SoftResult[F32] {
  let mut exp_a = exp_f32_ui(ui_a)
  let mut sig_a = frac_f32_ui(ui_a)
  let exp_b = exp_f32_ui(ui_b)
  let mut sig_b = frac_f32_ui(ui_b)
  let mut exp_diff = exp_a - exp_b
  if exp_diff == 0 {
    if exp_a == 0xFF {
      if (sig_a | sig_b) != 0U {
        f32_propagate_nan_result(context, ui_a, ui_b)
      } else {
        {
          value: F32::from_bits(default_nan_f32_ui(context.specialization)),
          context: context.raise_flags(ExceptionFlags::invalid()),
        }
      }
    } else {
      let mut sig_diff = sig_a.reinterpret_as_int() - sig_b.reinterpret_as_int()
      if sig_diff == 0 {
        {
          value: F32::from_bits(pack_to_f32_ui(context.rounding == Min, 0, 0U)),
          context,
        }
      } else {
        if exp_a != 0 {
          exp_a = exp_a - 1
        }
        let mut sign_z = sign_f32_ui(ui_a)
        if sig_diff < 0 {
          sign_z = !sign_z
          sig_diff = -sig_diff
        }
        let mut shift_dist = count_leading_zeros32(
            sig_diff.reinterpret_as_uint(),
          ) -
          8
        let mut exp_z = exp_a - shift_dist
        if exp_z < 0 {
          shift_dist = exp_a
          exp_z = 0
        }
        {
          value: F32::from_bits(
            pack_to_f32_ui(
              sign_z,
              exp_z,
              sig_diff.reinterpret_as_uint() << shift_dist,
            ),
          ),
          context,
        }
      }
    }
  } else {
    let mut sign_z = sign_f32_ui(ui_a)
    sig_a = sig_a << 7
    sig_b = sig_b << 7
    let mut exp_z = 0
    let mut sig_x = 0U
    let mut sig_y = 0U
    if exp_diff < 0 {
      sign_z = !sign_z
      if exp_b == 0xFF {
        if sig_b != 0U {
          return f32_propagate_nan_result(context, ui_a, ui_b)
        }
        return {
          value: F32::from_bits(pack_to_f32_ui(sign_z, 0xFF, 0U)),
          context,
        }
      }
      exp_z = exp_b - 1
      sig_x = sig_b | 0x40000000U
      sig_y = sig_a + (if exp_a != 0 { 0x40000000U } else { sig_a })
      exp_diff = -exp_diff
    } else {
      if exp_a == 0xFF {
        if sig_a != 0U {
          return f32_propagate_nan_result(context, ui_a, ui_b)
        }
        return { value: F32::from_bits(ui_a), context }
      }
      exp_z = exp_a - 1
      sig_x = sig_a | 0x40000000U
      sig_y = sig_b + (if exp_b != 0 { 0x40000000U } else { sig_b })
    }
    norm_round_pack_to_f32(
      context,
      sign_z,
      exp_z,
      sig_x - shift_right_jam32(sig_y, exp_diff),
    )
  }
}

///|
/// Adds `rhs` to this F32 value using the explicit SoftFloat context.
///
/// NaNs propagate, signaling NaNs raise `Invalid`, and opposite-signed
/// infinities raise `Invalid` with the specialization default NaN. Exact
/// cancellation returns `+0` except under round-min, where it returns `-0`.
/// Finite inexact results may raise `Inexact`, `Underflow`, or
/// `Overflow | Inexact`.
pub fn F32::add(self : F32, context : Context, rhs : F32) -> SoftResult[F32] {
  f32_add(context, self, rhs)
}

///|
/// Subtracts `rhs` from this F32 value using the explicit SoftFloat context.
///
/// NaNs propagate, signaling NaNs raise `Invalid`, and subtracting equal-signed
/// infinities raises `Invalid`. Exact cancellation returns a signed zero chosen
/// by the rounding mode.
pub fn F32::sub(self : F32, context : Context, rhs : F32) -> SoftResult[F32] {
  f32_sub(context, self, rhs)
}

///|
/// Function-style wrapper for SoftFloat `f32_add`.
///
/// Equivalent to `a.add(context, b)`.
pub fn f32_add(context : Context, a : F32, b : F32) -> SoftResult[F32] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  if sign_f32_ui(ui_a) != sign_f32_ui(ui_b) {
    f32_sub_mags(context, ui_a, ui_b)
  } else {
    f32_add_mags(context, ui_a, ui_b)
  }
}

///|
/// Function-style wrapper for SoftFloat `f32_sub`.
///
/// Equivalent to `a.sub(context, b)`.
pub fn f32_sub(context : Context, a : F32, b : F32) -> SoftResult[F32] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  if sign_f32_ui(ui_a) != sign_f32_ui(ui_b) {
    f32_add_mags(context, ui_a, ui_b)
  } else {
    f32_sub_mags(context, ui_a, ui_b)
  }
}

///|
/// Multiplies this F32 value by `rhs` using the explicit SoftFloat context.
///
/// NaNs propagate, signaling NaNs raise `Invalid`, and `0 * infinity` raises
/// `Invalid`. Otherwise infinities and zeros use the XOR of operand signs.
/// Finite products are rounded in the supplied context and may raise the usual
/// rounding, underflow, and overflow flags.
pub fn F32::mul(self : F32, context : Context, rhs : F32) -> SoftResult[F32] {
  f32_mul(context, self, rhs)
}

///|
/// Function-style wrapper for SoftFloat `f32_mul`.
///
/// Equivalent to `a.mul(context, b)`.
pub fn f32_mul(context : Context, a : F32, b : F32) -> SoftResult[F32] {
  let ui_a = a.to_bits()
  let sign_a = sign_f32_ui(ui_a)
  let mut exp_a = exp_f32_ui(ui_a)
  let mut sig_a = frac_f32_ui(ui_a)
  let ui_b = b.to_bits()
  let sign_b = sign_f32_ui(ui_b)
  let mut exp_b = exp_f32_ui(ui_b)
  let mut sig_b = frac_f32_ui(ui_b)
  let sign_z = sign_a != sign_b
  if exp_a == 0xFF {
    if sig_a != 0U || (exp_b == 0xFF && sig_b != 0U) {
      return f32_propagate_nan_result(context, ui_a, ui_b)
    }
    if exp_b == 0 && sig_b == 0U {
      return {
        value: F32::from_bits(default_nan_f32_ui(context.specialization)),
        context: context.raise_flags(ExceptionFlags::invalid()),
      }
    }
    return { value: F32::from_bits(pack_to_f32_ui(sign_z, 0xFF, 0U)), context }
  }
  if exp_b == 0xFF {
    if sig_b != 0U {
      return f32_propagate_nan_result(context, ui_a, ui_b)
    }
    if exp_a == 0 && sig_a == 0U {
      return {
        value: F32::from_bits(default_nan_f32_ui(context.specialization)),
        context: context.raise_flags(ExceptionFlags::invalid()),
      }
    }
    return { value: F32::from_bits(pack_to_f32_ui(sign_z, 0xFF, 0U)), context }
  }
  if exp_a == 0 {
    if sig_a == 0U {
      return { value: F32::from_bits(pack_to_f32_ui(sign_z, 0, 0U)), context }
    }
    let norm = norm_subnormal_f32_sig(sig_a)
    exp_a = norm.exp
    sig_a = norm.sig
  }
  if exp_b == 0 {
    if sig_b == 0U {
      return { value: F32::from_bits(pack_to_f32_ui(sign_z, 0, 0U)), context }
    }
    let norm = norm_subnormal_f32_sig(sig_b)
    exp_b = norm.exp
    sig_b = norm.sig
  }
  let mut exp_z = exp_a + exp_b - 0x7F
  sig_a = (sig_a | 0x00800000U) << 7
  sig_b = (sig_b | 0x00800000U) << 8
  let mut sig_z = short_shift_right_jam64(
    sig_a.to_uint64() * sig_b.to_uint64(),
    32,
  ).to_uint()
  if sig_z < 0x40000000U {
    exp_z = exp_z - 1
    sig_z = sig_z << 1
  }
  round_pack_to_f32(context, sign_z, exp_z, sig_z)
}

///|
/// Divides this F32 value by `rhs` using the explicit SoftFloat context.
///
/// NaNs propagate. `infinity / infinity` and `0 / 0` raise `Invalid`.
/// Nonzero finite division by zero raises `Infinite` and returns signed
/// infinity. Finite division by infinity returns signed zero.
pub fn F32::div(self : F32, context : Context, rhs : F32) -> SoftResult[F32] {
  f32_div(context, self, rhs)
}

///|
/// Function-style wrapper for SoftFloat `f32_div`.
///
/// Equivalent to `a.div(context, b)`.
pub fn f32_div(context : Context, a : F32, b : F32) -> SoftResult[F32] {
  let ui_a = a.to_bits()
  let sign_a = sign_f32_ui(ui_a)
  let mut exp_a = exp_f32_ui(ui_a)
  let mut sig_a = frac_f32_ui(ui_a)
  let ui_b = b.to_bits()
  let sign_b = sign_f32_ui(ui_b)
  let mut exp_b = exp_f32_ui(ui_b)
  let mut sig_b = frac_f32_ui(ui_b)
  let sign_z = sign_a != sign_b
  if exp_a == 0xFF {
    if sig_a != 0U {
      return f32_propagate_nan_result(context, ui_a, ui_b)
    }
    if exp_b == 0xFF {
      if sig_b != 0U {
        return f32_propagate_nan_result(context, ui_a, ui_b)
      }
      return {
        value: F32::from_bits(default_nan_f32_ui(context.specialization)),
        context: context.raise_flags(ExceptionFlags::invalid()),
      }
    }
    return { value: F32::from_bits(pack_to_f32_ui(sign_z, 0xFF, 0U)), context }
  }
  if exp_b == 0xFF {
    if sig_b != 0U {
      return f32_propagate_nan_result(context, ui_a, ui_b)
    }
    return { value: F32::from_bits(pack_to_f32_ui(sign_z, 0, 0U)), context }
  }
  if exp_b == 0 {
    if sig_b == 0U {
      if exp_a == 0 && sig_a == 0U {
        return {
          value: F32::from_bits(default_nan_f32_ui(context.specialization)),
          context: context.raise_flags(ExceptionFlags::invalid()),
        }
      }
      return {
        value: F32::from_bits(pack_to_f32_ui(sign_z, 0xFF, 0U)),
        context: context.raise_flags(ExceptionFlags::infinite()),
      }
    }
    let norm = norm_subnormal_f32_sig(sig_b)
    exp_b = norm.exp
    sig_b = norm.sig
  }
  if exp_a == 0 {
    if sig_a == 0U {
      return { value: F32::from_bits(pack_to_f32_ui(sign_z, 0, 0U)), context }
    }
    let norm = norm_subnormal_f32_sig(sig_a)
    exp_a = norm.exp
    sig_a = norm.sig
  }
  let mut exp_z = exp_a - exp_b + 0x7E
  sig_a = sig_a | 0x00800000U
  sig_b = sig_b | 0x00800000U
  if sig_a < sig_b {
    exp_z = exp_z - 1
    sig_a = sig_a << 8
  } else {
    sig_a = sig_a << 7
  }
  sig_b = sig_b << 8
  let recip = approx_recip32_1(sig_b)
  let mut sig_z = ((sig_a.to_uint64() * recip.to_uint64()) >> 32).to_uint()
  sig_z = sig_z + 2U
  if (sig_z & 0x3FU) < 2U {
    sig_z = sig_z & 0xFFFFFFFCU
    let rem = (sig_a.to_uint64() << 31) - sig_z.to_uint64() * sig_b.to_uint64()
    if (rem & 0x8000000000000000UL) != 0UL {
      sig_z = sig_z - 4U
    } else if rem != 0UL {
      sig_z = sig_z | 1U
    }
  }
  round_pack_to_f32(context, sign_z, exp_z, sig_z)
}

///|
/// Computes the square root of this F32 value using the explicit context.
///
/// NaNs propagate. `+infinity` and signed zeros are returned unchanged.
/// Negative nonzero values and `-infinity` raise `Invalid` and return the
/// specialization default NaN. Inexact finite roots may raise `Inexact`.
pub fn F32::sqrt(self : F32, context : Context) -> SoftResult[F32] {
  f32_sqrt(context, self)
}

///|
/// Function-style wrapper for SoftFloat `f32_sqrt`.
///
/// Equivalent to `a.sqrt(context)`.
pub fn f32_sqrt(context : Context, a : F32) -> SoftResult[F32] {
  let ui_a = a.to_bits()
  let sign_a = sign_f32_ui(ui_a)
  let mut exp_a = exp_f32_ui(ui_a)
  let mut sig_a = frac_f32_ui(ui_a)
  if exp_a == 0xFF {
    if sig_a != 0U {
      return f32_propagate_nan_result(context, ui_a, 0U)
    }
    if !sign_a {
      return { value: a, context }
    }
    return {
      value: F32::from_bits(default_nan_f32_ui(context.specialization)),
      context: context.raise_flags(ExceptionFlags::invalid()),
    }
  }
  if sign_a {
    if exp_a == 0 && sig_a == 0U {
      return { value: a, context }
    }
    return {
      value: F32::from_bits(default_nan_f32_ui(context.specialization)),
      context: context.raise_flags(ExceptionFlags::invalid()),
    }
  }
  if exp_a == 0 {
    if sig_a == 0U {
      return { value: a, context }
    }
    let norm = norm_subnormal_f32_sig(sig_a)
    exp_a = norm.exp
    sig_a = norm.sig
  }
  let exp_a_lsb = if exp_a / 2 * 2 == exp_a { 0 } else { 1 }
  let exp_z = ((exp_a - 0x7F) >> 1) + 0x7E
  sig_a = (sig_a | 0x00800000U) << 8
  let mut sig_z = ((
    sig_a.to_uint64() * approx_recip_sqrt32_1(exp_a_lsb != 0, sig_a).to_uint64()
  ) >>
  32).to_uint()
  if exp_a_lsb != 0 {
    sig_z = sig_z >> 1
  }
  sig_z = sig_z + 2U
  if (sig_z & 0x3FU) < 2U {
    let shifted_sig_z = sig_z >> 2
    let neg_rem = shifted_sig_z * shifted_sig_z
    sig_z = sig_z & 0xFFFFFFFCU
    if (neg_rem & 0x80000000U) != 0U {
      sig_z = sig_z | 1U
    } else if neg_rem != 0U {
      sig_z = sig_z - 1U
    }
  }
  round_pack_to_f32(context, false, exp_z, sig_z)
}

///|
/// Computes the IEEE remainder of this F32 value divided by `rhs`.
///
/// NaNs propagate. An infinite dividend or zero divisor raises `Invalid`; a
/// finite dividend with an infinite divisor is returned unchanged. Quotient
/// ties follow SoftFloat even-tie behavior, and the final remainder is
/// normalized with the expected IEEE sign.
pub fn F32::rem(self : F32, context : Context, rhs : F32) -> SoftResult[F32] {
  f32_rem(context, self, rhs)
}

///|
/// Function-style wrapper for SoftFloat `f32_rem`.
///
/// Equivalent to `a.rem(context, b)`.
pub fn f32_rem(context : Context, a : F32, b : F32) -> SoftResult[F32] {
  let ui_a = a.to_bits()
  let sign_a = sign_f32_ui(ui_a)
  let mut exp_a = exp_f32_ui(ui_a)
  let mut sig_a = frac_f32_ui(ui_a)
  let ui_b = b.to_bits()
  let mut exp_b = exp_f32_ui(ui_b)
  let mut sig_b = frac_f32_ui(ui_b)
  if exp_a == 0xFF {
    if sig_a != 0U || (exp_b == 0xFF && sig_b != 0U) {
      return f32_propagate_nan_result(context, ui_a, ui_b)
    }
    return {
      value: F32::from_bits(default_nan_f32_ui(context.specialization)),
      context: context.raise_flags(ExceptionFlags::invalid()),
    }
  }
  if exp_b == 0xFF {
    if sig_b != 0U {
      return f32_propagate_nan_result(context, ui_a, ui_b)
    }
    return { value: a, context }
  }
  if exp_b == 0 {
    if sig_b == 0U {
      return {
        value: F32::from_bits(default_nan_f32_ui(context.specialization)),
        context: context.raise_flags(ExceptionFlags::invalid()),
      }
    }
    let norm = norm_subnormal_f32_sig(sig_b)
    exp_b = norm.exp
    sig_b = norm.sig
  }
  if exp_a == 0 {
    if sig_a == 0U {
      return { value: a, context }
    }
    let norm = norm_subnormal_f32_sig(sig_a)
    exp_a = norm.exp
    sig_a = norm.sig
  }
  let mut rem = sig_a | 0x00800000U
  sig_b = sig_b | 0x00800000U
  let mut exp_diff = exp_a - exp_b
  let mut q = 0U
  if exp_diff < 1 {
    if exp_diff < -1 {
      return { value: a, context }
    }
    sig_b = sig_b << 6
    if exp_diff != 0 {
      rem = rem << 5
    } else {
      rem = rem << 6
      if sig_b <= rem {
        q = 1U
        rem = rem - sig_b
      }
    }
  } else {
    let recip32 = approx_recip32_1(sig_b << 8)
    rem = rem << 7
    exp_diff = exp_diff - 31
    sig_b = sig_b << 6
    while true {
      q = ((rem.to_uint64() * recip32.to_uint64()) >> 32).to_uint()
      if exp_diff < 0 {
        break
      }
      rem = 0U - q * sig_b
      exp_diff = exp_diff - 29
    }
    q = q >> (-exp_diff - 1)
    rem = (rem << (exp_diff + 30)) - q * sig_b
  }
  let mut alt_rem = 0U
  while true {
    alt_rem = rem
    q = q + 1U
    rem = rem - sig_b
    if (rem & 0x80000000U) != 0U {
      break
    }
  }
  let mean_rem = rem + alt_rem
  if (mean_rem & 0x80000000U) != 0U || (mean_rem == 0U && (q & 1U) != 0U) {
    rem = alt_rem
  }
  let mut sign_rem = sign_a
  if rem >= 0x80000000U {
    sign_rem = !sign_rem
    rem = 0U - rem
  }
  norm_round_pack_to_f32(context, sign_rem, exp_b, rem)
}

///|
/// Computes fused `(self * rhs) + addend` for F32 values.
///
/// The product and addend are combined before a single final rounding. NaNs
/// propagate, signaling NaNs raise `Invalid`, `0 * infinity` raises `Invalid`,
/// and an infinite product plus an opposite-signed infinity raises `Invalid`.
/// Complete cancellation returns a signed zero selected by the rounding mode.
pub fn F32::mul_add(
  self : F32,
  context : Context,
  rhs : F32,
  addend : F32,
) -> SoftResult[F32] {
  f32_mul_add(context, self, rhs, addend)
}

///|
/// Function-style wrapper for SoftFloat `f32_mulAdd`.
///
/// Equivalent to `a.mul_add(context, b, c)`.
pub fn f32_mul_add(
  context : Context,
  a : F32,
  b : F32,
  c : F32,
) -> SoftResult[F32] {
  let ui_a = a.to_bits()
  let sign_a = sign_f32_ui(ui_a)
  let mut exp_a = exp_f32_ui(ui_a)
  let mut sig_a = frac_f32_ui(ui_a)
  let ui_b = b.to_bits()
  let sign_b = sign_f32_ui(ui_b)
  let mut exp_b = exp_f32_ui(ui_b)
  let mut sig_b = frac_f32_ui(ui_b)
  let ui_c = c.to_bits()
  let sign_c = sign_f32_ui(ui_c)
  let mut exp_c = exp_f32_ui(ui_c)
  let mut sig_c = frac_f32_ui(ui_c)
  let sign_prod = sign_a != sign_b
  if exp_a == 0xFF {
    if sig_a != 0U || (exp_b == 0xFF && sig_b != 0U) {
      return f32_propagate_nan3_result(context, ui_a, ui_b, ui_c)
    }
    return f32_mul_add_inf_prod(
      context, sign_prod, exp_b, sig_b, sign_c, exp_c, sig_c, ui_c,
    )
  }
  if exp_b == 0xFF {
    if sig_b != 0U {
      return f32_propagate_nan3_result(context, ui_a, ui_b, ui_c)
    }
    return f32_mul_add_inf_prod(
      context, sign_prod, exp_a, sig_a, sign_c, exp_c, sig_c, ui_c,
    )
  }
  if exp_c == 0xFF {
    if sig_c != 0U {
      return f32_propagate_nan_result(context, 0U, ui_c)
    }
    return { value: c, context }
  }
  if exp_a == 0 {
    if sig_a == 0U {
      return f32_mul_add_zero_prod(
        context, sign_prod, sign_c, exp_c, sig_c, ui_c,
      )
    }
    let norm = norm_subnormal_f32_sig(sig_a)
    exp_a = norm.exp
    sig_a = norm.sig
  }
  if exp_b == 0 {
    if sig_b == 0U {
      return f32_mul_add_zero_prod(
        context, sign_prod, sign_c, exp_c, sig_c, ui_c,
      )
    }
    let norm = norm_subnormal_f32_sig(sig_b)
    exp_b = norm.exp
    sig_b = norm.sig
  }
  let mut exp_prod = exp_a + exp_b - 0x7E
  sig_a = (sig_a | 0x00800000U) << 7
  sig_b = (sig_b | 0x00800000U) << 7
  let mut sig_prod = sig_a.to_uint64() * sig_b.to_uint64()
  if sig_prod < 0x2000000000000000UL {
    exp_prod = exp_prod - 1
    sig_prod = sig_prod << 1
  }
  let mut sign_z = sign_prod
  if exp_c == 0 {
    if sig_c == 0U {
      return round_pack_to_f32(
        context,
        sign_z,
        exp_prod - 1,
        short_shift_right_jam64(sig_prod, 31).to_uint(),
      )
    }
    let norm = norm_subnormal_f32_sig(sig_c)
    exp_c = norm.exp
    sig_c = norm.sig
  }
  sig_c = (sig_c | 0x00800000U) << 6
  let exp_diff = exp_prod - exp_c
  let mut exp_z = 0
  let mut sig_z = 0U
  if sign_prod == sign_c {
    if exp_diff <= 0 {
      exp_z = exp_c
      sig_z = sig_c + shift_right_jam64(sig_prod, 32 - exp_diff).to_uint()
    } else {
      exp_z = exp_prod
      let sig64_z = sig_prod +
        shift_right_jam64(sig_c.to_uint64() << 32, exp_diff)
      sig_z = short_shift_right_jam64(sig64_z, 32).to_uint()
    }
    if sig_z < 0x40000000U {
      exp_z = exp_z - 1
      sig_z = sig_z << 1
    }
  } else {
    let sig64_c = sig_c.to_uint64() << 32
    let mut sig64_z = 0UL
    if exp_diff < 0 {
      sign_z = sign_c
      exp_z = exp_c
      sig64_z = sig64_c - shift_right_jam64(sig_prod, -exp_diff)
    } else if exp_diff == 0 {
      exp_z = exp_prod
      sig64_z = sig_prod - sig64_c
      if sig64_z == 0UL {
        return {
          value: F32::from_bits(pack_to_f32_ui(context.rounding == Min, 0, 0U)),
          context,
        }
      }
      if (sig64_z & 0x8000000000000000UL) != 0UL {
        sign_z = !sign_z
        sig64_z = 0UL - sig64_z
      }
    } else {
      exp_z = exp_prod
      sig64_z = sig_prod - shift_right_jam64(sig64_c, exp_diff)
    }
    let mut shift_dist = count_leading_zeros64(sig64_z) - 1
    exp_z = exp_z - shift_dist
    shift_dist = shift_dist - 32
    if shift_dist < 0 {
      sig_z = short_shift_right_jam64(sig64_z, -shift_dist).to_uint()
    } else {
      sig_z = (sig64_z << shift_dist).to_uint()
    }
  }
  round_pack_to_f32(context, sign_z, exp_z, sig_z)
}

///|
fn f32_mul_add_inf_prod(
  context : Context,
  sign_prod : Bool,
  exp_mag : Int,
  sig_mag : UInt,
  sign_c : Bool,
  exp_c : Int,
  sig_c : UInt,
  ui_c : UInt,
) -> SoftResult[F32] {
  if exp_mag != 0 || sig_mag != 0U {
    let ui_z = pack_to_f32_ui(sign_prod, 0xFF, 0U)
    if exp_c != 0xFF {
      return { value: F32::from_bits(ui_z), context }
    }
    if sig_c != 0U {
      return f32_propagate_nan_result(context, ui_z, ui_c)
    }
    if sign_prod == sign_c {
      return { value: F32::from_bits(ui_z), context }
    }
  }
  let invalid_context = context.raise_flags(ExceptionFlags::invalid())
  f32_propagate_nan_result(
    invalid_context,
    default_nan_f32_ui(context.specialization),
    ui_c,
  )
}

///|
fn f32_mul_add_zero_prod(
  context : Context,
  sign_prod : Bool,
  sign_c : Bool,
  exp_c : Int,
  sig_c : UInt,
  ui_c : UInt,
) -> SoftResult[F32] {
  if exp_c == 0 && sig_c == 0U && sign_prod != sign_c {
    {
      value: F32::from_bits(pack_to_f32_ui(context.rounding == Min, 0, 0U)),
      context,
    }
  } else {
    { value: F32::from_bits(ui_c), context }
  }
}

///|
fn f32_invalid_ui32_result(
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
fn f32_invalid_i32_result(
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
fn f32_invalid_ui64_result(
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
fn f32_invalid_i64_result(
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
/// Converts F32 to unsigned 32-bit integer with operation-local rounding.
///
/// `exact` controls whether rounded finite inputs raise `Inexact`. Negative
/// nonzero values, NaNs, infinities, and values outside UInt32 after rounding
/// raise `Invalid`; invalid integer constants follow `context.specialization`.
/// Negative zero converts to `0`.
pub fn F32::to_ui32(
  self : F32,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[UInt] {
  let bits = self.to_bits()
  let sign = sign_f32_ui(bits)
  let exp = exp_f32_ui(bits)
  let mut sig = frac_f32_ui(bits)
  if exp == 0xFF && sig != 0U {
    f32_invalid_ui32_result(context, sign, true)
  } else {
    if exp != 0 {
      sig = sig | 0x00800000U
    }
    let mut sig64 = sig.to_uint64() << 32
    let shift_dist = 0xAA - exp
    if shift_dist > 0 {
      sig64 = shift_right_jam64(sig64, shift_dist)
    }
    round_to_ui32(context, sign, sig64, rounding, exact)
  }
}

///|
/// Converts F32 to signed 32-bit integer with operation-local rounding.
///
/// NaNs, infinities, and values outside the Int32 range after rounding raise
/// `Invalid`. The exact value `-2147483648` is valid. Fractional finite inputs
/// raise `Inexact` only when `exact` is true.
pub fn F32::to_i32(
  self : F32,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[Int] {
  let bits = self.to_bits()
  let sign = sign_f32_ui(bits)
  let exp = exp_f32_ui(bits)
  let mut sig = frac_f32_ui(bits)
  if exp == 0xFF && sig != 0U {
    f32_invalid_i32_result(context, sign, true)
  } else {
    if exp != 0 {
      sig = sig | 0x00800000U
    }
    let mut sig64 = sig.to_uint64() << 32
    let shift_dist = 0xAA - exp
    if shift_dist > 0 {
      sig64 = shift_right_jam64(sig64, shift_dist)
    }
    round_to_i32(context, sign, sig64, rounding, exact)
  }
}

///|
/// Converts F32 to unsigned 64-bit integer with operation-local rounding.
///
/// Negative nonzero values, NaNs, infinities, and values outside UInt64 after
/// rounding raise `Invalid`; negative zero converts to `0`. Fractional finite
/// inputs raise `Inexact` according to `exact`.
pub fn F32::to_ui64(
  self : F32,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[UInt64] {
  let bits = self.to_bits()
  let sign = sign_f32_ui(bits)
  let exp = exp_f32_ui(bits)
  let mut sig = frac_f32_ui(bits)
  let shift_dist = 0xBE - exp
  if shift_dist < 0 {
    f32_invalid_ui64_result(context, sign, exp == 0xFF && sig != 0U)
  } else {
    if exp != 0 {
      sig = sig | 0x00800000U
    }
    let mut sig64 = sig.to_uint64() << 40
    let mut extra = 0UL
    if shift_dist != 0 {
      let shifted = shift_right_jam64_extra(sig64, 0UL, shift_dist)
      sig64 = shifted.value
      extra = shifted.extra
    }
    round_to_ui64(context, sign, sig64, extra, rounding, exact)
  }
}

///|
/// Converts F32 to signed 64-bit integer with operation-local rounding.
///
/// NaNs, infinities, and values outside Int64 after rounding raise `Invalid`.
/// The exact value `-9223372036854775808` is valid. `exact` controls only
/// whether discarded finite fractional bits raise `Inexact`.
pub fn F32::to_i64(
  self : F32,
  context : Context,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[Int64] {
  let bits = self.to_bits()
  let sign = sign_f32_ui(bits)
  let exp = exp_f32_ui(bits)
  let mut sig = frac_f32_ui(bits)
  let shift_dist = 0xBE - exp
  if shift_dist < 0 {
    f32_invalid_i64_result(context, sign, exp == 0xFF && sig != 0U)
  } else {
    if exp != 0 {
      sig = sig | 0x00800000U
    }
    let mut sig64 = sig.to_uint64() << 40
    let mut extra = 0UL
    if shift_dist != 0 {
      let shifted = shift_right_jam64_extra(sig64, 0UL, shift_dist)
      sig64 = shifted.value
      extra = shifted.extra
    }
    round_to_i64(context, sign, sig64, extra, rounding, exact)
  }
}

///|
/// Converts F32 to unsigned 32-bit integer using round-minMag.
///
/// This `_r_minMag` form truncates finite values toward zero regardless of
/// `context.rounding`. Magnitudes below 1 return `0` and may raise `Inexact`.
/// Negative nonzero values, NaNs, infinities, and out-of-range values raise
/// `Invalid`.
pub fn F32::to_ui32_min_mag(
  self : F32,
  context : Context,
  exact : Bool,
) -> SoftResult[UInt] {
  let bits = self.to_bits()
  let exp = exp_f32_ui(bits)
  let mut sig = frac_f32_ui(bits)
  let shift_dist = 0x9E - exp
  if shift_dist >= 32 {
    let context = if exact && (exp != 0 || sig != 0U) {
      context.raise_flags(ExceptionFlags::inexact())
    } else {
      context
    }
    { value: 0U, context }
  } else {
    let sign = sign_f32_ui(bits)
    if sign || shift_dist < 0 {
      f32_invalid_ui32_result(context, sign, exp == 0xFF && sig != 0U)
    } else {
      sig = (sig | 0x00800000U) << 8
      let value = sig >> shift_dist
      let context = if exact && value << shift_dist != sig {
        context.raise_flags(ExceptionFlags::inexact())
      } else {
        context
      }
      { value, context }
    }
  }
}

///|
/// Converts F32 to signed 32-bit integer using round-minMag.
///
/// Finite values truncate toward zero. The exact lower bound `-2147483648` is
/// accepted; values beyond the Int32 range, NaNs, and infinities raise
/// `Invalid`. `exact` controls `Inexact` for discarded fractional bits.
pub fn F32::to_i32_min_mag(
  self : F32,
  context : Context,
  exact : Bool,
) -> SoftResult[Int] {
  let bits = self.to_bits()
  let exp = exp_f32_ui(bits)
  let mut sig = frac_f32_ui(bits)
  let shift_dist = 0x9E - exp
  if shift_dist >= 32 {
    let context = if exact && (exp != 0 || sig != 0U) {
      context.raise_flags(ExceptionFlags::inexact())
    } else {
      context
    }
    { value: 0, context }
  } else {
    let sign = sign_f32_ui(bits)
    if shift_dist <= 0 {
      if bits == pack_to_f32_ui(true, 0x9E, 0U) {
        { value: -0x7FFFFFFF - 1, context }
      } else {
        f32_invalid_i32_result(context, sign, exp == 0xFF && sig != 0U)
      }
    } else {
      sig = (sig | 0x00800000U) << 8
      let abs_value = (sig >> shift_dist).reinterpret_as_int()
      let context = if exact &&
        abs_value.reinterpret_as_uint() << shift_dist != sig {
        context.raise_flags(ExceptionFlags::inexact())
      } else {
        context
      }
      { value: if sign { -abs_value } else { abs_value }, context }
    }
  }
}

///|
fn f32_min_mag_lost_bits(sig : UInt, shift_dist : Int) -> Bool {
  let lost_shift = 40 - shift_dist
  lost_shift < 0 && sig << (32 + lost_shift) != 0U
}

///|
/// Converts F32 to unsigned 64-bit integer using round-minMag.
///
/// Finite values truncate toward zero. Values with magnitude below 1 return
/// `0`; negative nonzero, NaN, infinity, and out-of-range inputs raise
/// `Invalid`.
pub fn F32::to_ui64_min_mag(
  self : F32,
  context : Context,
  exact : Bool,
) -> SoftResult[UInt64] {
  let bits = self.to_bits()
  let exp = exp_f32_ui(bits)
  let mut sig = frac_f32_ui(bits)
  let shift_dist = 0xBE - exp
  if shift_dist >= 64 {
    let context = if exact && (exp != 0 || sig != 0U) {
      context.raise_flags(ExceptionFlags::inexact())
    } else {
      context
    }
    { value: 0UL, context }
  } else {
    let sign = sign_f32_ui(bits)
    if sign || shift_dist < 0 {
      f32_invalid_ui64_result(context, sign, exp == 0xFF && sig != 0U)
    } else {
      sig = sig | 0x00800000U
      let sig64 = sig.to_uint64() << 40
      let value = sig64 >> shift_dist
      let context = if exact && f32_min_mag_lost_bits(sig, shift_dist) {
        context.raise_flags(ExceptionFlags::inexact())
      } else {
        context
      }
      { value, context }
    }
  }
}

///|
/// Converts F32 to signed 64-bit integer using round-minMag.
///
/// Finite values truncate toward zero. The exact lower bound
/// `-9223372036854775808` is accepted; values beyond the Int64 range, NaNs,
/// and infinities raise `Invalid`.
pub fn F32::to_i64_min_mag(
  self : F32,
  context : Context,
  exact : Bool,
) -> SoftResult[Int64] {
  let bits = self.to_bits()
  let exp = exp_f32_ui(bits)
  let mut sig = frac_f32_ui(bits)
  let shift_dist = 0xBE - exp
  if shift_dist >= 64 {
    let context = if exact && (exp != 0 || sig != 0U) {
      context.raise_flags(ExceptionFlags::inexact())
    } else {
      context
    }
    { value: 0L, context }
  } else {
    let sign = sign_f32_ui(bits)
    if shift_dist <= 0 {
      if bits == pack_to_f32_ui(true, 0xBE, 0U) {
        { value: -0x7FFFFFFFFFFFFFFFL - 1L, context }
      } else {
        f32_invalid_i64_result(context, sign, exp == 0xFF && sig != 0U)
      }
    } else {
      sig = sig | 0x00800000U
      let sig64 = sig.to_uint64() << 40
      let abs_value = (sig64 >> shift_dist).reinterpret_as_int64()
      let context = if exact && f32_min_mag_lost_bits(sig, shift_dist) {
        context.raise_flags(ExceptionFlags::inexact())
      } else {
        context
      }
      { value: if sign { -abs_value } else { abs_value }, context }
    }
  }
}

///|
/// Function-style wrapper for SoftFloat `f32_to_ui32`.
///
/// Equivalent to `a.to_ui32(context, rounding, exact)`.
pub fn f32_to_ui32(
  context : Context,
  a : F32,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[UInt] {
  a.to_ui32(context, rounding, exact)
}

///|
/// Function-style wrapper for SoftFloat `f32_to_ui64`.
///
/// Equivalent to `a.to_ui64(context, rounding, exact)`.
pub fn f32_to_ui64(
  context : Context,
  a : F32,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[UInt64] {
  a.to_ui64(context, rounding, exact)
}

///|
/// Function-style wrapper for SoftFloat `f32_to_i32`.
///
/// Equivalent to `a.to_i32(context, rounding, exact)`.
pub fn f32_to_i32(
  context : Context,
  a : F32,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[Int] {
  a.to_i32(context, rounding, exact)
}

///|
/// Function-style wrapper for SoftFloat `f32_to_i64`.
///
/// Equivalent to `a.to_i64(context, rounding, exact)`.
pub fn f32_to_i64(
  context : Context,
  a : F32,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[Int64] {
  a.to_i64(context, rounding, exact)
}

///|
/// Function-style wrapper for SoftFloat `f32_to_ui32_r_minMag`.
///
/// Equivalent to `a.to_ui32_min_mag(context, exact)`.
pub fn f32_to_ui32_min_mag(
  context : Context,
  a : F32,
  exact : Bool,
) -> SoftResult[UInt] {
  a.to_ui32_min_mag(context, exact)
}

///|
/// Function-style wrapper for SoftFloat `f32_to_ui64_r_minMag`.
///
/// Equivalent to `a.to_ui64_min_mag(context, exact)`.
pub fn f32_to_ui64_min_mag(
  context : Context,
  a : F32,
  exact : Bool,
) -> SoftResult[UInt64] {
  a.to_ui64_min_mag(context, exact)
}

///|
/// Function-style wrapper for SoftFloat `f32_to_i32_r_minMag`.
///
/// Equivalent to `a.to_i32_min_mag(context, exact)`.
pub fn f32_to_i32_min_mag(
  context : Context,
  a : F32,
  exact : Bool,
) -> SoftResult[Int] {
  a.to_i32_min_mag(context, exact)
}

///|
/// Function-style wrapper for SoftFloat `f32_to_i64_r_minMag`.
///
/// Equivalent to `a.to_i64_min_mag(context, exact)`.
pub fn f32_to_i64_min_mag(
  context : Context,
  a : F32,
  exact : Bool,
) -> SoftResult[Int64] {
  a.to_i64_min_mag(context, exact)
}

///|
fn f32_both_zero(a : UInt, b : UInt) -> Bool {
  (a | b) << 1 == 0U
}

///|
fn f32_ordered_le(a : UInt, b : UInt) -> Bool {
  let sign_a = sign_f32_ui(a)
  let sign_b = sign_f32_ui(b)
  if sign_a != sign_b {
    sign_a || f32_both_zero(a, b)
  } else {
    a == b || sign_a != (a < b)
  }
}

///|
fn f32_ordered_lt(a : UInt, b : UInt) -> Bool {
  let sign_a = sign_f32_ui(a)
  let sign_b = sign_f32_ui(b)
  if sign_a != sign_b {
    sign_a && !f32_both_zero(a, b)
  } else {
    a != b && sign_a != (a < b)
  }
}

///|
fn f32_compare_nan_context(
  context : Context,
  a : UInt,
  b : UInt,
  quiet : Bool,
) -> Context {
  if is_nan_f32_ui(a) || is_nan_f32_ui(b) {
    if !quiet || is_sig_nan_f32_ui(a) || is_sig_nan_f32_ui(b) {
      context.raise_flags(ExceptionFlags::invalid())
    } else {
      context
    }
  } else {
    context
  }
}

///|
/// Implements SoftFloat `f32_eq`.
///
/// Quiet NaNs compare false; signaling NaNs raise `Invalid`. `+0` and `-0`
/// compare equal.
pub fn f32_eq(context : Context, a : F32, b : F32) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  let context = f32_compare_nan_context(context, ui_a, ui_b, true)
  if is_nan_f32_ui(ui_a) || is_nan_f32_ui(ui_b) {
    { value: false, context }
  } else {
    { value: ui_a == ui_b || f32_both_zero(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f32_eq_signaling`.
///
/// Any NaN operand raises `Invalid` and compares false. `+0` and `-0` compare
/// equal.
pub fn f32_eq_signaling(
  context : Context,
  a : F32,
  b : F32,
) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  let context = f32_compare_nan_context(context, ui_a, ui_b, false)
  if is_nan_f32_ui(ui_a) || is_nan_f32_ui(ui_b) {
    { value: false, context }
  } else {
    { value: ui_a == ui_b || f32_both_zero(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f32_le`.
///
/// Any NaN operand raises `Invalid` and compares false. Signed zeros compare
/// equal, so both zero orderings are true for less-or-equal.
pub fn f32_le(context : Context, a : F32, b : F32) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  if is_nan_f32_ui(ui_a) || is_nan_f32_ui(ui_b) {
    { value: false, context: context.raise_flags(ExceptionFlags::invalid()) }
  } else {
    { value: f32_ordered_le(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f32_lt`.
///
/// Any NaN operand raises `Invalid` and compares false. Signed zeros compare
/// equal, so neither zero is less than the other.
pub fn f32_lt(context : Context, a : F32, b : F32) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  if is_nan_f32_ui(ui_a) || is_nan_f32_ui(ui_b) {
    { value: false, context: context.raise_flags(ExceptionFlags::invalid()) }
  } else {
    { value: f32_ordered_lt(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f32_le_quiet`.
///
/// Quiet NaNs compare false without flags; signaling NaNs raise `Invalid`.
/// Signed zeros compare equal.
pub fn f32_le_quiet(context : Context, a : F32, b : F32) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  let context = f32_compare_nan_context(context, ui_a, ui_b, true)
  if is_nan_f32_ui(ui_a) || is_nan_f32_ui(ui_b) {
    { value: false, context }
  } else {
    { value: f32_ordered_le(ui_a, ui_b), context }
  }
}

///|
/// Implements SoftFloat `f32_lt_quiet`.
///
/// Quiet NaNs compare false without flags; signaling NaNs raise `Invalid`.
/// Signed zeros compare equal, so zero-vs-zero is never less-than.
pub fn f32_lt_quiet(context : Context, a : F32, b : F32) -> SoftResult[Bool] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  let context = f32_compare_nan_context(context, ui_a, ui_b, true)
  if is_nan_f32_ui(ui_a) || is_nan_f32_ui(ui_b) {
    { value: false, context }
  } else {
    { value: f32_ordered_lt(ui_a, ui_b), context }
  }
}
