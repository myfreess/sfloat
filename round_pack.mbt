///|
priv struct ExpSig16 {
  exp : Int
  sig : UInt16
}

///|
priv struct ExpSig32 {
  exp : Int
  sig : UInt
}

///|
priv struct ExpSig64 {
  exp : Int
  sig : UInt64
}

///|
fn round_pack_increment(
  rounding : RoundingMode,
  sign : Bool,
  half : UInt,
) -> UInt {
  match rounding {
    NearEven | NearMaxMag => half
    Min if sign => (half << 1) - 1U
    Max if !sign => (half << 1) - 1U
    _ => 0U
  }
}

///|
fn round_pack_increment64(
  rounding : RoundingMode,
  sign : Bool,
  half : UInt64,
) -> UInt64 {
  match rounding {
    NearEven | NearMaxMag => half
    Min if sign => (half << 1) - 1UL
    Max if !sign => (half << 1) - 1UL
    _ => 0UL
  }
}

///|
fn round_pack_raise_overflow_inexact(context : Context) -> Context {
  context.raise_flags(
    ExceptionFlags::overflow().merge(ExceptionFlags::inexact()),
  )
}

///|
/// Ports `softfloat_normSubnormalF16Sig` from `s_normSubnormalF16Sig.c`.
fn norm_subnormal_f16_sig(sig : UInt16) -> ExpSig16 {
  let shift_dist = count_leading_zeros16(sig) - 5
  { exp: 1 - shift_dist, sig: sig << shift_dist }
}

///|
/// Ports `softfloat_normSubnormalF32Sig` from `s_normSubnormalF32Sig.c`.
fn norm_subnormal_f32_sig(sig : UInt) -> ExpSig32 {
  let shift_dist = count_leading_zeros32(sig) - 8
  { exp: 1 - shift_dist, sig: sig << shift_dist }
}

///|
/// Ports `softfloat_normSubnormalF64Sig` from `s_normSubnormalF64Sig.c`.
fn norm_subnormal_f64_sig(sig : UInt64) -> ExpSig64 {
  let shift_dist = count_leading_zeros64(sig) - 11
  { exp: 1 - shift_dist, sig: sig << shift_dist }
}

///|
/// Ports `softfloat_roundPackToF16` from `s_roundPackToF16.c`.
fn round_pack_to_f16(
  context : Context,
  sign : Bool,
  exp : Int,
  sig : UInt,
) -> SoftResult[F16] {
  let round_increment = round_pack_increment(context.rounding, sign, 0x8U)
  let mut exp = exp
  let mut sig = sig
  let mut round_bits = sig & 0xFU
  let mut context = context
  if exp < 0 || exp >= 0x1D {
    if exp < 0 {
      let is_tiny = context.tininess == BeforeRounding ||
        exp < -1 ||
        sig + round_increment < 0x8000U
      sig = shift_right_jam32(sig, -exp)
      exp = 0
      round_bits = sig & 0xFU
      if is_tiny && round_bits != 0U {
        context = context.raise_flags(ExceptionFlags::underflow())
      }
    } else if exp > 0x1D || sig + round_increment >= 0x8000U {
      let inf = pack_to_f16_ui(sign, 0x1F, 0)
      let value = if round_increment == 0U { inf - 1 } else { inf }
      return {
        value: F16::from_bits(value),
        context: round_pack_raise_overflow_inexact(context),
      }
    }
  }
  sig = (sig + round_increment) >> 4
  if round_bits != 0U {
    context = context.raise_flags(ExceptionFlags::inexact())
    if context.rounding == Odd {
      sig = sig | 1U
      return {
        value: F16::from_bits(pack_to_f16_ui(sign, exp, sig.to_uint16())),
        context,
      }
    }
  }
  if round_bits == 0x8U && context.rounding == NearEven {
    sig = sig & 0xFFFFFFFEU
  }
  if sig == 0U {
    exp = 0
  }
  { value: F16::from_bits(pack_to_f16_ui(sign, exp, sig.to_uint16())), context }
}

///|
/// Ports `softfloat_roundPackToBF16` from `s_roundPackToBF16.c`.
fn round_pack_to_bf16(
  context : Context,
  sign : Bool,
  exp : Int,
  sig : UInt,
) -> SoftResult[BF16] {
  let round_increment = round_pack_increment(context.rounding, sign, 0x40U)
  let mut exp = exp
  let mut sig = sig
  let mut round_bits = sig & 0x7FU
  let mut context = context
  if exp < 0 || exp >= 0xFD {
    if exp < 0 {
      let is_tiny = context.tininess == BeforeRounding ||
        exp < -1 ||
        sig + round_increment < 0x8000U
      sig = shift_right_jam32(sig, -exp)
      exp = 0
      round_bits = sig & 0x7FU
      if is_tiny && round_bits != 0U {
        context = context.raise_flags(ExceptionFlags::underflow())
      }
    } else if exp > 0xFD || sig + round_increment >= 0x8000U {
      let inf = pack_to_bf16_ui(sign, 0xFF, 0)
      let value = if round_increment == 0U { inf - 1 } else { inf }
      return {
        value: BF16::from_bits(value),
        context: round_pack_raise_overflow_inexact(context),
      }
    }
  }
  sig = (sig + round_increment) >> 7
  if round_bits != 0U {
    context = context.raise_flags(ExceptionFlags::inexact())
    if context.rounding == Odd {
      sig = sig | 1U
      return {
        value: BF16::from_bits(pack_to_bf16_ui(sign, exp, sig.to_uint16())),
        context,
      }
    }
  }
  if round_bits == 0x40U && context.rounding == NearEven {
    sig = sig & 0xFFFFFFFEU
  }
  if sig == 0U {
    exp = 0
  }
  {
    value: BF16::from_bits(pack_to_bf16_ui(sign, exp, sig.to_uint16())),
    context,
  }
}

///|
/// Ports `softfloat_roundPackToF32` from `s_roundPackToF32.c`.
fn round_pack_to_f32(
  context : Context,
  sign : Bool,
  exp : Int,
  sig : UInt,
) -> SoftResult[F32] {
  let round_increment = round_pack_increment(context.rounding, sign, 0x40U)
  let mut exp = exp
  let mut sig = sig
  let mut round_bits = sig & 0x7FU
  let mut context = context
  if exp < 0 || exp >= 0xFD {
    if exp < 0 {
      let is_tiny = context.tininess == BeforeRounding ||
        exp < -1 ||
        sig + round_increment < 0x80000000U
      sig = shift_right_jam32(sig, -exp)
      exp = 0
      round_bits = sig & 0x7FU
      if is_tiny && round_bits != 0U {
        context = context.raise_flags(ExceptionFlags::underflow())
      }
    } else if exp > 0xFD || sig + round_increment >= 0x80000000U {
      let inf = pack_to_f32_ui(sign, 0xFF, 0U)
      let value = if round_increment == 0U { inf - 1U } else { inf }
      return {
        value: F32::from_bits(value),
        context: round_pack_raise_overflow_inexact(context),
      }
    }
  }
  sig = (sig + round_increment) >> 7
  if round_bits != 0U {
    context = context.raise_flags(ExceptionFlags::inexact())
    if context.rounding == Odd {
      sig = sig | 1U
      return { value: F32::from_bits(pack_to_f32_ui(sign, exp, sig)), context }
    }
  }
  if round_bits == 0x40U && context.rounding == NearEven {
    sig = sig & 0xFFFFFFFEU
  }
  if sig == 0U {
    exp = 0
  }
  { value: F32::from_bits(pack_to_f32_ui(sign, exp, sig)), context }
}

///|
/// Ports `softfloat_roundPackToF64` from `s_roundPackToF64.c`.
fn round_pack_to_f64(
  context : Context,
  sign : Bool,
  exp : Int,
  sig : UInt64,
) -> SoftResult[F64] {
  let round_increment = round_pack_increment64(context.rounding, sign, 0x200UL)
  let mut exp = exp
  let mut sig = sig
  let mut round_bits = sig & 0x3FFUL
  let mut context = context
  if exp < 0 || exp >= 0x7FD {
    if exp < 0 {
      let is_tiny = context.tininess == BeforeRounding ||
        exp < -1 ||
        sig + round_increment < 0x8000000000000000UL
      sig = shift_right_jam64(sig, -exp)
      exp = 0
      round_bits = sig & 0x3FFUL
      if is_tiny && round_bits != 0UL {
        context = context.raise_flags(ExceptionFlags::underflow())
      }
    } else if exp > 0x7FD || sig + round_increment >= 0x8000000000000000UL {
      let inf = pack_to_f64_ui(sign, 0x7FF, 0UL)
      let value = if round_increment == 0UL { inf - 1UL } else { inf }
      return {
        value: F64::from_bits(value),
        context: round_pack_raise_overflow_inexact(context),
      }
    }
  }
  sig = (sig + round_increment) >> 10
  if round_bits != 0UL {
    context = context.raise_flags(ExceptionFlags::inexact())
    if context.rounding == Odd {
      sig = sig | 1UL
      return { value: F64::from_bits(pack_to_f64_ui(sign, exp, sig)), context }
    }
  }
  if round_bits == 0x200UL && context.rounding == NearEven {
    sig = sig & 0xFFFFFFFFFFFFFFFEUL
  }
  if sig == 0UL {
    exp = 0
  }
  { value: F64::from_bits(pack_to_f64_ui(sign, exp, sig)), context }
}

///|
/// Ports `softfloat_normRoundPackToF16` from `s_normRoundPackToF16.c`.
fn norm_round_pack_to_f16(
  context : Context,
  sign : Bool,
  exp : Int,
  sig : UInt,
) -> SoftResult[F16] {
  let shift_dist = count_leading_zeros16(sig.to_uint16()) - 1
  let exp = exp - shift_dist
  if shift_dist >= 4 && exp >= 0 && exp < 0x1D {
    let packed_sig = if sig == 0U { 0U } else { sig << (shift_dist - 4) }
    let packed_exp = if sig == 0U { 0 } else { exp }
    {
      value: F16::from_bits(
        pack_to_f16_ui(sign, packed_exp, packed_sig.to_uint16()),
      ),
      context,
    }
  } else {
    round_pack_to_f16(context, sign, exp, sig << shift_dist)
  }
}

///|
/// Ports `softfloat_normRoundPackToF32` from `s_normRoundPackToF32.c`.
fn norm_round_pack_to_f32(
  context : Context,
  sign : Bool,
  exp : Int,
  sig : UInt,
) -> SoftResult[F32] {
  let shift_dist = count_leading_zeros32(sig) - 1
  let exp = exp - shift_dist
  if shift_dist >= 7 && exp >= 0 && exp < 0xFD {
    let packed_sig = if sig == 0U { 0U } else { sig << (shift_dist - 7) }
    let packed_exp = if sig == 0U { 0 } else { exp }
    {
      value: F32::from_bits(pack_to_f32_ui(sign, packed_exp, packed_sig)),
      context,
    }
  } else {
    round_pack_to_f32(context, sign, exp, sig << shift_dist)
  }
}

///|
/// Ports `softfloat_normRoundPackToF64` from `s_normRoundPackToF64.c`.
fn norm_round_pack_to_f64(
  context : Context,
  sign : Bool,
  exp : Int,
  sig : UInt64,
) -> SoftResult[F64] {
  let shift_dist = count_leading_zeros64(sig) - 1
  let exp = exp - shift_dist
  if shift_dist >= 10 && exp >= 0 && exp < 0x7FD {
    let packed_sig = if sig == 0UL { 0UL } else { sig << (shift_dist - 10) }
    let packed_exp = if sig == 0UL { 0 } else { exp }
    {
      value: F64::from_bits(pack_to_f64_ui(sign, packed_exp, packed_sig)),
      context,
    }
  } else {
    round_pack_to_f64(context, sign, exp, sig << shift_dist)
  }
}
