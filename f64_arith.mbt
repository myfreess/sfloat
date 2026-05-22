///|
fn f64_propagate_nan3_result(
  context : Context,
  ui_a : UInt64,
  ui_b : UInt64,
  ui_c : UInt64,
) -> SoftResult[F64] {
  let ab = propagate_nan_f64_ui(context, ui_a, ui_b)
  let abc = propagate_nan_f64_ui(ab.context, ab.value, ui_c)
  { value: F64::from_bits(abc.value), context: abc.context }
}

///|
fn f64_invalid_result(context : Context) -> SoftResult[F64] {
  {
    value: F64::from_bits(default_nan_f64_ui(context.specialization)),
    context: context.raise_flags(ExceptionFlags::invalid()),
  }
}

///|
fn f64_add_mags(
  context : Context,
  ui_a : UInt64,
  ui_b : UInt64,
) -> SoftResult[F64] {
  let exp_a = exp_f64_ui(ui_a)
  let mut sig_a = frac_f64_ui(ui_a)
  let exp_b = exp_f64_ui(ui_b)
  let mut sig_b = frac_f64_ui(ui_b)
  let exp_diff = exp_a - exp_b
  if exp_diff == 0 {
    if exp_a == 0 {
      { value: F64::from_bits(ui_a + sig_b), context }
    } else if exp_a == 0x7FF {
      if (sig_a | sig_b) != 0UL {
        f64_propagate_nan_result(context, ui_a, ui_b)
      } else {
        { value: F64::from_bits(ui_a), context }
      }
    } else {
      let sign_z = sign_f64_ui(ui_a)
      let sig_z = (0x0020000000000000UL + sig_a + sig_b) << 9
      round_pack_to_f64(context, sign_z, exp_a, sig_z)
    }
  } else {
    let sign_z = sign_f64_ui(ui_a)
    sig_a = sig_a << 9
    sig_b = sig_b << 9
    let mut exp_z = 0
    if exp_diff < 0 {
      if exp_b == 0x7FF {
        if sig_b != 0UL {
          return f64_propagate_nan_result(context, ui_a, ui_b)
        }
        return {
          value: F64::from_bits(pack_to_f64_ui(sign_z, 0x7FF, 0UL)),
          context,
        }
      }
      exp_z = exp_b
      if exp_a != 0 {
        sig_a = sig_a + 0x2000000000000000UL
      } else {
        sig_a = sig_a << 1
      }
      sig_a = shift_right_jam64(sig_a, -exp_diff)
    } else {
      if exp_a == 0x7FF {
        if sig_a != 0UL {
          return f64_propagate_nan_result(context, ui_a, ui_b)
        }
        return { value: F64::from_bits(ui_a), context }
      }
      exp_z = exp_a
      if exp_b != 0 {
        sig_b = sig_b + 0x2000000000000000UL
      } else {
        sig_b = sig_b << 1
      }
      sig_b = shift_right_jam64(sig_b, exp_diff)
    }
    let mut sig_z = 0x2000000000000000UL + sig_a + sig_b
    if sig_z < 0x4000000000000000UL {
      exp_z = exp_z - 1
      sig_z = sig_z << 1
    }
    round_pack_to_f64(context, sign_z, exp_z, sig_z)
  }
}

///|
fn f64_sub_mags(
  context : Context,
  ui_a : UInt64,
  ui_b : UInt64,
) -> SoftResult[F64] {
  let mut exp_a = exp_f64_ui(ui_a)
  let mut sig_a = frac_f64_ui(ui_a)
  let exp_b = exp_f64_ui(ui_b)
  let mut sig_b = frac_f64_ui(ui_b)
  let exp_diff = exp_a - exp_b
  if exp_diff == 0 {
    if exp_a == 0x7FF {
      if (sig_a | sig_b) != 0UL {
        f64_propagate_nan_result(context, ui_a, ui_b)
      } else {
        f64_invalid_result(context)
      }
    } else {
      let mut sig_diff = sig_a.reinterpret_as_int64() -
        sig_b.reinterpret_as_int64()
      if sig_diff == 0L {
        {
          value: F64::from_bits(pack_to_f64_ui(context.rounding == Min, 0, 0UL)),
          context,
        }
      } else {
        if exp_a != 0 {
          exp_a = exp_a - 1
        }
        let mut sign_z = sign_f64_ui(ui_a)
        if sig_diff < 0L {
          sign_z = !sign_z
          sig_diff = -sig_diff
        }
        let mut shift_dist = count_leading_zeros64(
            sig_diff.reinterpret_as_uint64(),
          ) -
          11
        let mut exp_z = exp_a - shift_dist
        if exp_z < 0 {
          shift_dist = exp_a
          exp_z = 0
        }
        {
          value: F64::from_bits(
            pack_to_f64_ui(
              sign_z,
              exp_z,
              sig_diff.reinterpret_as_uint64() << shift_dist,
            ),
          ),
          context,
        }
      }
    }
  } else {
    let mut sign_z = sign_f64_ui(ui_a)
    sig_a = sig_a << 10
    sig_b = sig_b << 10
    let mut exp_z = 0
    let mut sig_z = 0UL
    if exp_diff < 0 {
      sign_z = !sign_z
      if exp_b == 0x7FF {
        if sig_b != 0UL {
          return f64_propagate_nan_result(context, ui_a, ui_b)
        }
        return {
          value: F64::from_bits(pack_to_f64_ui(sign_z, 0x7FF, 0UL)),
          context,
        }
      }
      sig_a = sig_a + (if exp_a != 0 { 0x4000000000000000UL } else { sig_a })
      sig_a = shift_right_jam64(sig_a, -exp_diff)
      sig_b = sig_b | 0x4000000000000000UL
      exp_z = exp_b
      sig_z = sig_b - sig_a
    } else {
      if exp_a == 0x7FF {
        if sig_a != 0UL {
          return f64_propagate_nan_result(context, ui_a, ui_b)
        }
        return { value: F64::from_bits(ui_a), context }
      }
      sig_b = sig_b + (if exp_b != 0 { 0x4000000000000000UL } else { sig_b })
      sig_b = shift_right_jam64(sig_b, exp_diff)
      sig_a = sig_a | 0x4000000000000000UL
      exp_z = exp_a
      sig_z = sig_a - sig_b
    }
    norm_round_pack_to_f64(context, sign_z, exp_z - 1, sig_z)
  }
}

///|
/// Adds `rhs` to this F64 value using the rounding/tininess and specialization
/// carried by `context`.
///
/// NaNs propagate, signaling NaNs raise `Invalid`, and adding opposite-signed
/// infinities raises `Invalid` with the specialization default NaN. Exact
/// cancellation returns `+0` except under round-min, where it returns `-0`.
/// Finite inexact results may raise `Inexact`, `Underflow`, or
/// `Overflow | Inexact`.
pub fn F64::add(self : F64, context : Context, rhs : F64) -> SoftResult[F64] {
  f64_add(context, self, rhs)
}

///|
/// Subtracts `rhs` from this F64 value using the explicit SoftFloat context.
///
/// NaNs propagate, signaling NaNs raise `Invalid`, and subtracting equal-signed
/// infinities raises `Invalid`. Exact cancellation returns a signed zero chosen
/// by the rounding mode.
pub fn F64::sub(self : F64, context : Context, rhs : F64) -> SoftResult[F64] {
  f64_sub(context, self, rhs)
}

///|
/// Function-style wrapper for SoftFloat `f64_add`.
///
/// The returned context accumulates IEEE flags including `Invalid` for
/// infinity cancellation and `Inexact`/`Overflow`/`Underflow` from rounding.
/// This is equivalent to `a.add(context, b)`.
pub fn f64_add(context : Context, a : F64, b : F64) -> SoftResult[F64] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  if sign_f64_ui(ui_a) != sign_f64_ui(ui_b) {
    f64_sub_mags(context, ui_a, ui_b)
  } else {
    f64_add_mags(context, ui_a, ui_b)
  }
}

///|
/// Function-style wrapper for SoftFloat `f64_sub`.
///
/// NaN propagation and invalid-result defaults follow `context.specialization`.
/// This is equivalent to `a.sub(context, b)`.
pub fn f64_sub(context : Context, a : F64, b : F64) -> SoftResult[F64] {
  let ui_a = a.to_bits()
  let ui_b = b.to_bits()
  if sign_f64_ui(ui_a) != sign_f64_ui(ui_b) {
    f64_add_mags(context, ui_a, ui_b)
  } else {
    f64_sub_mags(context, ui_a, ui_b)
  }
}

///|
/// Multiplies this F64 value by `rhs` using the explicit SoftFloat context.
///
/// NaNs propagate, signaling NaNs raise `Invalid`, and `0 * infinity` raises
/// `Invalid`. Otherwise infinities and zeros use the XOR of operand signs.
/// Finite products are rounded in the supplied context and may raise the usual
/// rounding, underflow, and overflow flags.
pub fn F64::mul(self : F64, context : Context, rhs : F64) -> SoftResult[F64] {
  f64_mul(context, self, rhs)
}

///|
/// Function-style wrapper for SoftFloat `f64_mul`.
///
/// `0 * infinity` raises `Invalid`; finite products round according to
/// `context.rounding` and use tininess detection from `context.tininess`.
/// This is equivalent to `a.mul(context, b)`.
pub fn f64_mul(context : Context, a : F64, b : F64) -> SoftResult[F64] {
  let ui_a = a.to_bits()
  let sign_a = sign_f64_ui(ui_a)
  let mut exp_a = exp_f64_ui(ui_a)
  let mut sig_a = frac_f64_ui(ui_a)
  let ui_b = b.to_bits()
  let sign_b = sign_f64_ui(ui_b)
  let mut exp_b = exp_f64_ui(ui_b)
  let mut sig_b = frac_f64_ui(ui_b)
  let sign_z = sign_a != sign_b
  if exp_a == 0x7FF {
    if sig_a != 0UL || (exp_b == 0x7FF && sig_b != 0UL) {
      return f64_propagate_nan_result(context, ui_a, ui_b)
    }
    if exp_b == 0 && sig_b == 0UL {
      return f64_invalid_result(context)
    }
    return {
      value: F64::from_bits(pack_to_f64_ui(sign_z, 0x7FF, 0UL)),
      context,
    }
  }
  if exp_b == 0x7FF {
    if sig_b != 0UL {
      return f64_propagate_nan_result(context, ui_a, ui_b)
    }
    if exp_a == 0 && sig_a == 0UL {
      return f64_invalid_result(context)
    }
    return {
      value: F64::from_bits(pack_to_f64_ui(sign_z, 0x7FF, 0UL)),
      context,
    }
  }
  if exp_a == 0 {
    if sig_a == 0UL {
      return { value: F64::from_bits(pack_to_f64_ui(sign_z, 0, 0UL)), context }
    }
    let norm = norm_subnormal_f64_sig(sig_a)
    exp_a = norm.exp
    sig_a = norm.sig
  }
  if exp_b == 0 {
    if sig_b == 0UL {
      return { value: F64::from_bits(pack_to_f64_ui(sign_z, 0, 0UL)), context }
    }
    let norm = norm_subnormal_f64_sig(sig_b)
    exp_b = norm.exp
    sig_b = norm.sig
  }
  let mut exp_z = exp_a + exp_b - 0x3FF
  sig_a = (sig_a | 0x0010000000000000UL) << 10
  sig_b = (sig_b | 0x0010000000000000UL) << 11
  let sig128_z = mul64_to_128(sig_a, sig_b)
  let mut sig_z = sig128_z.hi | (if sig128_z.lo != 0UL { 1UL } else { 0UL })
  if sig_z < 0x4000000000000000UL {
    exp_z = exp_z - 1
    sig_z = sig_z << 1
  }
  round_pack_to_f64(context, sign_z, exp_z, sig_z)
}

///|
/// Divides this F64 value by `rhs` using the explicit SoftFloat context.
///
/// NaNs propagate. `infinity / infinity` and `0 / 0` raise `Invalid`.
/// Nonzero finite division by zero raises `Infinite` and returns signed
/// infinity. Finite division by infinity returns signed zero.
pub fn F64::div(self : F64, context : Context, rhs : F64) -> SoftResult[F64] {
  f64_div(context, self, rhs)
}

///|
/// Function-style wrapper for SoftFloat `f64_div`.
///
/// Division by zero raises `Infinite` for nonzero numerators and `Invalid` for
/// `0 / 0`; NaNs are propagated according to the selected specialization. This
/// is equivalent to `a.div(context, b)`.
pub fn f64_div(context : Context, a : F64, b : F64) -> SoftResult[F64] {
  let ui_a = a.to_bits()
  let sign_a = sign_f64_ui(ui_a)
  let mut exp_a = exp_f64_ui(ui_a)
  let mut sig_a = frac_f64_ui(ui_a)
  let ui_b = b.to_bits()
  let sign_b = sign_f64_ui(ui_b)
  let mut exp_b = exp_f64_ui(ui_b)
  let mut sig_b = frac_f64_ui(ui_b)
  let sign_z = sign_a != sign_b
  if exp_a == 0x7FF {
    if sig_a != 0UL {
      return f64_propagate_nan_result(context, ui_a, ui_b)
    }
    if exp_b == 0x7FF {
      if sig_b != 0UL {
        return f64_propagate_nan_result(context, ui_a, ui_b)
      }
      return f64_invalid_result(context)
    }
    return {
      value: F64::from_bits(pack_to_f64_ui(sign_z, 0x7FF, 0UL)),
      context,
    }
  }
  if exp_b == 0x7FF {
    if sig_b != 0UL {
      return f64_propagate_nan_result(context, ui_a, ui_b)
    }
    return { value: F64::from_bits(pack_to_f64_ui(sign_z, 0, 0UL)), context }
  }
  if exp_b == 0 {
    if sig_b == 0UL {
      if exp_a == 0 && sig_a == 0UL {
        return f64_invalid_result(context)
      }
      return {
        value: F64::from_bits(pack_to_f64_ui(sign_z, 0x7FF, 0UL)),
        context: context.raise_flags(ExceptionFlags::infinite()),
      }
    }
    let norm = norm_subnormal_f64_sig(sig_b)
    exp_b = norm.exp
    sig_b = norm.sig
  }
  if exp_a == 0 {
    if sig_a == 0UL {
      return { value: F64::from_bits(pack_to_f64_ui(sign_z, 0, 0UL)), context }
    }
    let norm = norm_subnormal_f64_sig(sig_a)
    exp_a = norm.exp
    sig_a = norm.sig
  }
  let mut exp_z = exp_a - exp_b + 0x3FE
  sig_a = sig_a | 0x0010000000000000UL
  sig_b = sig_b | 0x0010000000000000UL
  if sig_a < sig_b {
    exp_z = exp_z - 1
    sig_a = sig_a << 11
  } else {
    sig_a = sig_a << 10
  }
  sig_b = sig_b << 11
  let recip32 = approx_recip32_1((sig_b >> 32).to_uint()) - 2U
  let sig32_z = (((sig_a >> 32).to_uint().to_uint64() * recip32.to_uint64()) >>
  32).to_uint()
  let mut double_term = sig32_z << 1
  let mut rem = (
      (sig_a - double_term.to_uint64() * (sig_b >> 32).to_uint().to_uint64()) <<
      28
    ) -
    double_term.to_uint64() * (sig_b.to_uint() >> 4).to_uint64()
  let mut q = (((rem >> 32).to_uint().to_uint64() * recip32.to_uint64()) >> 32).to_uint() +
    4U
  let mut sig_z = (sig32_z.to_uint64() << 32) + (q.to_uint64() << 4)
  if (sig_z & 0x1FFUL) < 4UL << 4 {
    q = q & 0xFFFFFFF8U
    sig_z = sig_z & (0xFFFFFFFFFFFFFFFFUL - 0x7FUL)
    double_term = q << 1
    rem = (
        (rem - double_term.to_uint64() * (sig_b >> 32).to_uint().to_uint64()) <<
        28
      ) -
      double_term.to_uint64() * (sig_b.to_uint() >> 4).to_uint64()
    if (rem & 0x8000000000000000UL) != 0UL {
      sig_z = sig_z - (1UL << 7)
    } else if rem != 0UL {
      sig_z = sig_z | 1UL
    }
  }
  round_pack_to_f64(context, sign_z, exp_z, sig_z)
}

///|
/// Computes the square root of this F64 value using the explicit context.
///
/// NaNs propagate. `+infinity` and signed zeros are returned unchanged.
/// Negative nonzero values and `-infinity` raise `Invalid` and return the
/// specialization default NaN. Inexact finite roots may raise `Inexact`.
pub fn F64::sqrt(self : F64, context : Context) -> SoftResult[F64] {
  f64_sqrt(context, self)
}

///|
/// Function-style wrapper for SoftFloat `f64_sqrt`.
///
/// Negative nonzero inputs raise `Invalid`; signed negative zero is returned
/// unchanged. Finite non-square roots may raise `Inexact`. This is equivalent
/// to `a.sqrt(context)`.
pub fn f64_sqrt(context : Context, a : F64) -> SoftResult[F64] {
  let ui_a = a.to_bits()
  let sign_a = sign_f64_ui(ui_a)
  let mut exp_a = exp_f64_ui(ui_a)
  let mut sig_a = frac_f64_ui(ui_a)
  if exp_a == 0x7FF {
    if sig_a != 0UL {
      return f64_propagate_nan_result(context, ui_a, 0UL)
    }
    if !sign_a {
      return { value: a, context }
    }
    return f64_invalid_result(context)
  }
  if sign_a {
    if exp_a == 0 && sig_a == 0UL {
      return { value: a, context }
    }
    return f64_invalid_result(context)
  }
  if exp_a == 0 {
    if sig_a == 0UL {
      return { value: a, context }
    }
    let norm = norm_subnormal_f64_sig(sig_a)
    exp_a = norm.exp
    sig_a = norm.sig
  }
  let odd_exp_a = exp_a / 2 * 2 != exp_a
  let exp_z = ((exp_a - 0x3FF) >> 1) + 0x3FE
  sig_a = sig_a | 0x0010000000000000UL
  let sig32_a = (sig_a >> 21).to_uint()
  let recip_sqrt32 = approx_recip_sqrt32_1(odd_exp_a, sig32_a)
  let mut sig32_z = ((sig32_a.to_uint64() * recip_sqrt32.to_uint64()) >> 32).to_uint()
  if odd_exp_a {
    sig_a = sig_a << 8
    sig32_z = sig32_z >> 1
  } else {
    sig_a = sig_a << 9
  }
  let mut rem = sig_a - sig32_z.to_uint64() * sig32_z.to_uint64()
  let q = (((rem >> 2).to_uint().to_uint64() * recip_sqrt32.to_uint64()) >> 32).to_uint()
  let mut sig_z = ((sig32_z.to_uint64() << 32) | (1UL << 5)) +
    (q.to_uint64() << 3)
  if (sig_z & 0x1FFUL) < 0x22UL {
    sig_z = sig_z & (0xFFFFFFFFFFFFFFFFUL - 0x3FUL)
    let shifted_sig_z = sig_z >> 6
    rem = (sig_a << 52) - shifted_sig_z * shifted_sig_z
    if (rem & 0x8000000000000000UL) != 0UL {
      sig_z = sig_z - 1UL
    } else if rem != 0UL {
      sig_z = sig_z | 1UL
    }
  }
  round_pack_to_f64(context, false, exp_z, sig_z)
}

///|
fn high_bit64(a : UInt64) -> Bool {
  (a & 0x8000000000000000UL) != 0UL
}

///|
/// Computes the IEEE remainder of this F64 value divided by `rhs`.
///
/// NaNs propagate. An infinite dividend or zero divisor raises `Invalid`; a
/// finite dividend with an infinite divisor is returned unchanged. Quotient
/// ties follow SoftFloat even-tie behavior, and the final remainder preserves
/// the expected IEEE sign.
pub fn F64::rem(self : F64, context : Context, rhs : F64) -> SoftResult[F64] {
  f64_rem(context, self, rhs)
}

///|
/// Function-style wrapper for SoftFloat `f64_rem`.
///
/// Infinite dividends and zero divisors raise `Invalid`; finite dividends with
/// infinite divisors are returned unchanged. This is equivalent to
/// `a.rem(context, b)`.
pub fn f64_rem(context : Context, a : F64, b : F64) -> SoftResult[F64] {
  let ui_a = a.to_bits()
  let sign_a = sign_f64_ui(ui_a)
  let mut exp_a = exp_f64_ui(ui_a)
  let mut sig_a = frac_f64_ui(ui_a)
  let ui_b = b.to_bits()
  let mut exp_b = exp_f64_ui(ui_b)
  let mut sig_b = frac_f64_ui(ui_b)
  if exp_a == 0x7FF {
    if sig_a != 0UL || (exp_b == 0x7FF && sig_b != 0UL) {
      return f64_propagate_nan_result(context, ui_a, ui_b)
    }
    return f64_invalid_result(context)
  }
  if exp_b == 0x7FF {
    if sig_b != 0UL {
      return f64_propagate_nan_result(context, ui_a, ui_b)
    }
    return { value: a, context }
  }
  if exp_a < exp_b - 1 {
    return { value: a, context }
  }
  if exp_b == 0 {
    if sig_b == 0UL {
      return f64_invalid_result(context)
    }
    let norm = norm_subnormal_f64_sig(sig_b)
    exp_b = norm.exp
    sig_b = norm.sig
  }
  if exp_a == 0 {
    if sig_a == 0UL {
      return { value: a, context }
    }
    let norm = norm_subnormal_f64_sig(sig_a)
    exp_a = norm.exp
    sig_a = norm.sig
  }
  let mut rem = sig_a | 0x0010000000000000UL
  sig_b = sig_b | 0x0010000000000000UL
  let mut exp_diff = exp_a - exp_b
  let mut q = 0U
  let mut alt_rem = 0UL
  let mut have_alt_rem = false
  if exp_diff < 1 {
    if exp_diff < -1 {
      return { value: a, context }
    }
    sig_b = sig_b << 9
    if exp_diff != 0 {
      rem = rem << 8
      q = 0U
    } else {
      rem = rem << 9
      if sig_b <= rem {
        q = 1U
        rem = rem - sig_b
      }
    }
  } else {
    let recip32 = approx_recip32_1((sig_b >> 21).to_uint())
    rem = rem << 9
    exp_diff = exp_diff - 30
    sig_b = sig_b << 9
    let mut q64 = 0UL
    while true {
      q64 = (rem >> 32).to_uint().to_uint64() * recip32.to_uint64()
      if exp_diff < 0 {
        break
      }
      q = ((q64 + 0x80000000UL) >> 32).to_uint()
      rem = (rem << 29) - q.to_uint64() * sig_b
      if high_bit64(rem) {
        rem = rem + sig_b
      }
      exp_diff = exp_diff - 29
    }
    q = (q64 >> 32).to_uint() >> (-exp_diff - 1)
    rem = (rem << (exp_diff + 30)) - q.to_uint64() * sig_b
    if high_bit64(rem) {
      alt_rem = rem + sig_b
      have_alt_rem = true
    }
  }
  if !have_alt_rem {
    while true {
      alt_rem = rem
      q = q + 1U
      rem = rem - sig_b
      if high_bit64(rem) {
        break
      }
    }
  }
  let mean_rem = rem + alt_rem
  if high_bit64(mean_rem) || (mean_rem == 0UL && (q & 1U) != 0U) {
    rem = alt_rem
  }
  let mut sign_rem = sign_a
  if high_bit64(rem) {
    sign_rem = !sign_rem
    rem = 0UL - rem
  }
  norm_round_pack_to_f64(context, sign_rem, exp_b, rem)
}

///|
/// Computes fused `(self * rhs) + addend` for F64 values.
///
/// The multiplication and addition are fused before rounding, matching
/// SoftFloat `f64_mulAdd`. NaNs propagate, signaling NaNs raise `Invalid`,
/// `0 * infinity` raises `Invalid`, and an infinite product plus an
/// opposite-signed infinity raises `Invalid`. Complete cancellation returns a
/// signed zero selected by the rounding mode.
pub fn F64::mul_add(
  self : F64,
  context : Context,
  rhs : F64,
  addend : F64,
) -> SoftResult[F64] {
  f64_mul_add(context, self, rhs, addend)
}

///|
/// Function-style wrapper for SoftFloat `f64_mulAdd`.
///
/// The returned context captures invalid infinity/zero products, infinity
/// cancellation, NaN propagation, and final rounding flags. This is equivalent
/// to `a.mul_add(context, b, c)`.
pub fn f64_mul_add(
  context : Context,
  a : F64,
  b : F64,
  c : F64,
) -> SoftResult[F64] {
  let ui_a = a.to_bits()
  let sign_a = sign_f64_ui(ui_a)
  let mut exp_a = exp_f64_ui(ui_a)
  let mut sig_a = frac_f64_ui(ui_a)
  let ui_b = b.to_bits()
  let sign_b = sign_f64_ui(ui_b)
  let mut exp_b = exp_f64_ui(ui_b)
  let mut sig_b = frac_f64_ui(ui_b)
  let ui_c = c.to_bits()
  let sign_c = sign_f64_ui(ui_c)
  let mut exp_c = exp_f64_ui(ui_c)
  let mut sig_c = frac_f64_ui(ui_c)
  let mut sign_z = sign_a != sign_b
  if exp_a == 0x7FF {
    if sig_a != 0UL || (exp_b == 0x7FF && sig_b != 0UL) {
      return f64_propagate_nan3_result(context, ui_a, ui_b, ui_c)
    }
    return f64_mul_add_inf_prod(
      context, sign_z, exp_b, sig_b, sign_c, exp_c, sig_c, ui_c,
    )
  }
  if exp_b == 0x7FF {
    if sig_b != 0UL {
      return f64_propagate_nan3_result(context, ui_a, ui_b, ui_c)
    }
    return f64_mul_add_inf_prod(
      context, sign_z, exp_a, sig_a, sign_c, exp_c, sig_c, ui_c,
    )
  }
  if exp_c == 0x7FF {
    if sig_c != 0UL {
      return f64_propagate_nan_result(context, 0UL, ui_c)
    }
    return { value: c, context }
  }
  if exp_a == 0 {
    if sig_a == 0UL {
      return f64_mul_add_zero_prod(context, sign_z, sign_c, exp_c, sig_c, ui_c)
    }
    let norm = norm_subnormal_f64_sig(sig_a)
    exp_a = norm.exp
    sig_a = norm.sig
  }
  if exp_b == 0 {
    if sig_b == 0UL {
      return f64_mul_add_zero_prod(context, sign_z, sign_c, exp_c, sig_c, ui_c)
    }
    let norm = norm_subnormal_f64_sig(sig_b)
    exp_b = norm.exp
    sig_b = norm.sig
  }
  let mut exp_z = exp_a + exp_b - 0x3FE
  sig_a = (sig_a | 0x0010000000000000UL) << 10
  sig_b = (sig_b | 0x0010000000000000UL) << 10
  let mut sig128_z = mul64_to_128(sig_a, sig_b)
  if sig128_z.hi < 0x2000000000000000UL {
    exp_z = exp_z - 1
    sig128_z = add128(sig128_z, sig128_z)
  }
  if exp_c == 0 {
    if sig_c == 0UL {
      exp_z = exp_z - 1
      let sig_z = (sig128_z.hi << 1) |
        (if sig128_z.lo != 0UL { 1UL } else { 0UL })
      return round_pack_to_f64(context, sign_z, exp_z, sig_z)
    }
    let norm = norm_subnormal_f64_sig(sig_c)
    exp_c = norm.exp
    sig_c = norm.sig
  }
  sig_c = (sig_c | 0x0010000000000000UL) << 9
  let exp_diff = exp_z - exp_c
  let mut sig128_c = uint128_zero()
  if exp_diff < 0 {
    exp_z = exp_c
    if sign_z == sign_c || exp_diff < -1 {
      sig128_z = { ..sig128_z, hi: shift_right_jam64(sig128_z.hi, -exp_diff) }
    } else {
      sig128_z = short_shift_right_jam128(sig128_z, 1)
    }
  } else if exp_diff != 0 {
    sig128_c = shift_right_jam128({ hi: sig_c, lo: 0UL }, exp_diff)
  }
  let mut sig_z = 0UL
  if sign_z == sign_c {
    if exp_diff <= 0 {
      sig_z = (sig_c + sig128_z.hi) |
        (if sig128_z.lo != 0UL { 1UL } else { 0UL })
    } else {
      sig128_z = add128(sig128_z, sig128_c)
      sig_z = sig128_z.hi | (if sig128_z.lo != 0UL { 1UL } else { 0UL })
    }
    if sig_z < 0x4000000000000000UL {
      exp_z = exp_z - 1
      sig_z = sig_z << 1
    }
  } else {
    if exp_diff < 0 {
      sign_z = sign_c
      sig128_z = sub128({ hi: sig_c, lo: 0UL }, sig128_z)
    } else if exp_diff == 0 {
      sig128_z = { ..sig128_z, hi: sig128_z.hi - sig_c }
      if (sig128_z.hi | sig128_z.lo) == 0UL {
        return f64_mul_add_complete_cancellation(context)
      }
      if high_bit64(sig128_z.hi) {
        sign_z = !sign_z
        sig128_z = neg128(sig128_z)
      }
    } else {
      sig128_z = sub128(sig128_z, sig128_c)
    }
    if sig128_z.hi == 0UL {
      exp_z = exp_z - 64
      sig128_z = { hi: sig128_z.lo, lo: 0UL }
    }
    let shift_dist = count_leading_zeros64(sig128_z.hi) - 1
    exp_z = exp_z - shift_dist
    if shift_dist < 0 {
      sig_z = short_shift_right_jam64(sig128_z.hi, -shift_dist)
    } else {
      sig128_z = short_shift_left128(sig128_z, shift_dist)
      sig_z = sig128_z.hi
    }
    sig_z = sig_z | (if sig128_z.lo != 0UL { 1UL } else { 0UL })
  }
  round_pack_to_f64(context, sign_z, exp_z, sig_z)
}

///|
fn f64_mul_add_inf_prod(
  context : Context,
  sign_prod : Bool,
  exp_mag : Int,
  sig_mag : UInt64,
  sign_c : Bool,
  exp_c : Int,
  sig_c : UInt64,
  ui_c : UInt64,
) -> SoftResult[F64] {
  if exp_mag != 0 || sig_mag != 0UL {
    let ui_z = pack_to_f64_ui(sign_prod, 0x7FF, 0UL)
    if exp_c != 0x7FF {
      return { value: F64::from_bits(ui_z), context }
    }
    if sig_c != 0UL {
      return f64_propagate_nan_result(context, ui_z, ui_c)
    }
    if sign_prod == sign_c {
      return { value: F64::from_bits(ui_z), context }
    }
  }
  let invalid_context = context.raise_flags(ExceptionFlags::invalid())
  f64_propagate_nan_result(
    invalid_context,
    default_nan_f64_ui(context.specialization),
    ui_c,
  )
}

///|
fn f64_mul_add_zero_prod(
  context : Context,
  sign_prod : Bool,
  sign_c : Bool,
  exp_c : Int,
  sig_c : UInt64,
  ui_c : UInt64,
) -> SoftResult[F64] {
  if exp_c == 0 && sig_c == 0UL && sign_prod != sign_c {
    f64_mul_add_complete_cancellation(context)
  } else {
    { value: F64::from_bits(ui_c), context }
  }
}

///|
fn f64_mul_add_complete_cancellation(context : Context) -> SoftResult[F64] {
  {
    value: F64::from_bits(pack_to_f64_ui(context.rounding == Min, 0, 0UL)),
    context,
  }
}
