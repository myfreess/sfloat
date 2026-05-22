///|
fn round_inexact_context(context : Context, exact : Bool) -> Context {
  if exact {
    context.raise_flags(ExceptionFlags::inexact())
  } else {
    context
  }
}

///|
fn round_invalid_context(context : Context) -> Context {
  context.raise_flags(ExceptionFlags::invalid())
}

///|
fn round_to_ui32_invalid(context : Context, sign : Bool) -> SoftResult[UInt] {
  let value = if sign {
    ui32_from_neg_overflow(context.specialization)
  } else {
    ui32_from_pos_overflow(context.specialization)
  }
  { value, context: round_invalid_context(context) }
}

///|
/// Ports `softfloat_roundToUI32` from `s_roundToUI32.c`.
fn round_to_ui32(
  context : Context,
  sign : Bool,
  sig : UInt64,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[UInt] {
  let round_increment = match rounding {
    NearEven | NearMaxMag => 0x800UL
    Max if !sign => 0xFFFUL
    _ => 0UL
  }
  if sign && sig != 0UL && (rounding == Min || rounding == Odd) {
    round_to_ui32_invalid(context, sign)
  } else {
    let round_bits = sig & 0xFFFUL
    let sig = sig + round_increment
    if (sig & 0xFFFFF00000000000UL) != 0UL {
      round_to_ui32_invalid(context, sign)
    } else {
      let mut value = (sig >> 12).to_uint()
      if round_bits == 0x800UL && rounding == NearEven {
        value = value & 0xFFFFFFFEU
      }
      if sign && value != 0U {
        round_to_ui32_invalid(context, sign)
      } else if round_bits != 0UL {
        if rounding == Odd {
          value = value | 1U
        }
        { value, context: round_inexact_context(context, exact) }
      } else {
        { value, context }
      }
    }
  }
}

///|
fn round_to_ui64_invalid(context : Context, sign : Bool) -> SoftResult[UInt64] {
  let value = if sign {
    ui64_from_neg_overflow(context.specialization)
  } else {
    ui64_from_pos_overflow(context.specialization)
  }
  { value, context: round_invalid_context(context) }
}

///|
/// Ports `softfloat_roundToUI64` from `s_roundToUI64.c`.
fn round_to_ui64(
  context : Context,
  sign : Bool,
  sig : UInt64,
  sig_extra : UInt64,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[UInt64] {
  if sign && (sig | sig_extra) != 0UL && (rounding == Min || rounding == Odd) {
    round_to_ui64_invalid(context, sign)
  } else {
    let increment = match rounding {
      NearEven | NearMaxMag => sig_extra >= 0x8000000000000000UL
      Max if !sign => sig_extra != 0UL
      _ => false
    }
    let incremented = if increment { sig + 1UL } else { sig }
    if increment && incremented == 0UL {
      round_to_ui64_invalid(context, sign)
    } else {
      let mut value = incremented
      if increment && sig_extra == 0x8000000000000000UL && rounding == NearEven {
        value = value & 0xFFFFFFFFFFFFFFFEUL
      }
      if sign && value != 0UL {
        round_to_ui64_invalid(context, sign)
      } else if sig_extra != 0UL {
        if rounding == Odd {
          value = value | 1UL
        }
        { value, context: round_inexact_context(context, exact) }
      } else {
        { value, context }
      }
    }
  }
}

///|
fn round_to_i32_invalid(context : Context, sign : Bool) -> SoftResult[Int] {
  let value = if sign {
    i32_from_neg_overflow(context.specialization)
  } else {
    i32_from_pos_overflow(context.specialization)
  }
  { value, context: round_invalid_context(context) }
}

///|
/// Ports `softfloat_roundToI32` from `s_roundToI32.c`.
fn round_to_i32(
  context : Context,
  sign : Bool,
  sig : UInt64,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[Int] {
  let round_increment = match rounding {
    NearEven | NearMaxMag => 0x800UL
    Min if sign => 0xFFFUL
    Odd if sign => 0xFFFUL
    Max if !sign => 0xFFFUL
    _ => 0UL
  }
  let round_bits = sig & 0xFFFUL
  let sig = sig + round_increment
  if (sig & 0xFFFFF00000000000UL) != 0UL {
    round_to_i32_invalid(context, sign)
  } else {
    let mut sig32 = (sig >> 12).to_uint()
    if round_bits == 0x800UL && rounding == NearEven {
      sig32 = sig32 & 0xFFFFFFFEU
    }
    let value_bits = if sign { 0U - sig32 } else { sig32 }
    let mut value = value_bits.reinterpret_as_int()
    if value != 0 && (value < 0) != sign {
      round_to_i32_invalid(context, sign)
    } else if round_bits != 0UL {
      if rounding == Odd {
        value = value | 1
      }
      { value, context: round_inexact_context(context, exact) }
    } else {
      { value, context }
    }
  }
}

///|
fn round_to_i64_invalid(context : Context, sign : Bool) -> SoftResult[Int64] {
  let value = if sign {
    i64_from_neg_overflow(context.specialization)
  } else {
    i64_from_pos_overflow(context.specialization)
  }
  { value, context: round_invalid_context(context) }
}

///|
/// Ports `softfloat_roundToI64` from `s_roundToI64.c`.
fn round_to_i64(
  context : Context,
  sign : Bool,
  sig : UInt64,
  sig_extra : UInt64,
  rounding : RoundingMode,
  exact : Bool,
) -> SoftResult[Int64] {
  let increment = match rounding {
    NearEven | NearMaxMag => sig_extra >= 0x8000000000000000UL
    Min if sign => sig_extra != 0UL
    Odd if sign => sig_extra != 0UL
    Max if !sign => sig_extra != 0UL
    _ => false
  }
  let incremented = if increment { sig + 1UL } else { sig }
  if increment && incremented == 0UL {
    round_to_i64_invalid(context, sign)
  } else {
    let mut value_bits = if sign { 0UL - incremented } else { incremented }
    if increment && sig_extra == 0x8000000000000000UL && rounding == NearEven {
      value_bits = value_bits & 0xFFFFFFFFFFFFFFFEUL
    }
    let mut value = value_bits.reinterpret_as_int64()
    if value != 0L && (value < 0L) != sign {
      round_to_i64_invalid(context, sign)
    } else if sig_extra != 0UL {
      if rounding == Odd {
        value = value | 1L
      }
      { value, context: round_inexact_context(context, exact) }
    } else {
      { value, context }
    }
  }
}
