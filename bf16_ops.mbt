///|
/// Converts BF16 to F32 with SoftFloat NaN handling.
///
/// Finite values, including signed zeros and subnormals, are widened exactly
/// by padding the BF16 fraction with 16 zero bits. Infinities keep their sign.
/// NaNs use the selected specialization's common-NaN conversion; signaling
/// NaNs raise `Invalid`, while quiet NaNs do not.
pub fn BF16::to_f32(self : BF16, context : Context) -> SoftResult[F32] {
  let bits = self.to_bits()
  let sign = sign_bf16_ui(bits)
  let exp = exp_bf16_ui(bits)
  let frac = frac_bf16_ui(bits)
  if exp == 0xFF {
    if frac != 0 {
      let common = bf16_ui_to_common_nan(context, bits)
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
    {
      value: F32::from_bits(pack_to_f32_ui(sign, exp, frac.to_uint() << 16)),
      context,
    }
  }
}

///|
/// Converts F32 to BF16 with SoftFloat rounding and NaN handling.
///
/// Finite values are rounded through `round_pack_to_bf16`, so the returned
/// context may accumulate `Inexact`, `Underflow`, or `Overflow`. NaNs use the
/// selected specialization's common-NaN conversion and raise `Invalid` for
/// signaling NaNs. Signed zeros and infinities keep their sign; overflow
/// rounds to infinity or the largest finite BF16 according to `context.rounding`.
pub fn F32::to_bf16(self : F32, context : Context) -> SoftResult[BF16] {
  let bits = self.to_bits()
  let sign = sign_f32_ui(bits)
  let exp = exp_f32_ui(bits)
  let frac = frac_f32_ui(bits)
  if exp == 0xFF {
    if frac != 0U {
      let common = f32_ui_to_common_nan(context, bits)
      {
        value: BF16::from_bits(
          common_nan_to_bf16_ui(common.context, common.value),
        ),
        context: common.context,
      }
    } else {
      { value: BF16::from_bits(pack_to_bf16_ui(sign, 0xFF, 0)), context }
    }
  } else {
    let frac16 = (frac >> 9) | (if (frac & 0x1FFU) != 0U { 1U } else { 0U })
    if (exp.reinterpret_as_uint() | frac16) == 0U {
      { value: BF16::from_bits(pack_to_bf16_ui(sign, 0, 0)), context }
    } else {
      let mask = if exp != 0 { 0x4000U } else { 0U }
      let shifted_frac = if exp != 0 { frac16 } else { frac16 << 1 }
      round_pack_to_bf16(context, sign, exp - 1, shifted_frac | mask)
    }
  }
}

///|
/// Function-style BF16-to-F32 wrapper for the SoftFloat C symbol.
///
/// Equivalent to `a.to_f32(context)`; no additional flags or canonicalization
/// are applied beyond the method behavior.
pub fn bf16_to_f32(context : Context, a : BF16) -> SoftResult[F32] {
  a.to_f32(context)
}

///|
/// Function-style F32-to-BF16 wrapper for the SoftFloat C symbol.
///
/// Equivalent to `a.to_bf16(context)`, including NaN handling and all rounding
/// flags.
pub fn f32_to_bf16(context : Context, a : F32) -> SoftResult[BF16] {
  a.to_bf16(context)
}

///|
/// Function-style BF16 signaling-NaN predicate wrapper.
///
/// Equivalent to `a.is_signaling_nan()` and raises no flags.
pub fn bf16_is_signaling_nan(a : BF16) -> Bool {
  a.is_signaling_nan()
}
