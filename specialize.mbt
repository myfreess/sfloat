///|
priv struct CommonNaN {
  sign : Bool
  v64 : UInt64
  v0 : UInt64
}

///|
/// Default F16 NaN constants from `source/*/specialize.h`.
fn default_nan_f16_ui(specialization : Specialization) -> UInt16 {
  match specialization {
    X86_8086SSE => 0xFE00
    RISCV => 0x7E00
  }
}

///|
/// Default BF16 NaN constants from `source/*/specialize.h`.
///
/// RISCV defines `defaultNaNBF16UI` directly. 8086-SSE preserves BF16 common
/// NaN sign and payload; this helper uses the sign-preserving quiet default
/// corresponding to the 8086-SSE common-NaN conversion path.
fn default_nan_bf16_ui(specialization : Specialization) -> UInt16 {
  match specialization {
    X86_8086SSE => 0xFFC0
    RISCV => 0x7FC0
  }
}

///|
/// Default F32 NaN constants from `source/*/specialize.h`.
fn default_nan_f32_ui(specialization : Specialization) -> UInt {
  match specialization {
    X86_8086SSE => 0xFFC00000U
    RISCV => 0x7FC00000U
  }
}

///|
/// Default F64 NaN constants from `source/*/specialize.h`.
fn default_nan_f64_ui(specialization : Specialization) -> UInt64 {
  match specialization {
    X86_8086SSE => 0xFFF8000000000000UL
    RISCV => 0x7FF8000000000000UL
  }
}

///|
/// Invalid unsigned 32-bit positive-overflow result from `source/*/specialize.h`.
fn ui32_from_pos_overflow(specialization : Specialization) -> UInt {
  match specialization {
    X86_8086SSE => 0xFFFFFFFFU
    RISCV => 0xFFFFFFFFU
  }
}

///|
/// Invalid unsigned 32-bit negative-overflow result from `source/*/specialize.h`.
fn ui32_from_neg_overflow(specialization : Specialization) -> UInt {
  match specialization {
    X86_8086SSE => 0xFFFFFFFFU
    RISCV => 0U
  }
}

///|
/// Invalid unsigned 32-bit NaN result from `source/*/specialize.h`.
fn ui32_from_nan(specialization : Specialization) -> UInt {
  match specialization {
    X86_8086SSE => 0xFFFFFFFFU
    RISCV => 0xFFFFFFFFU
  }
}

///|
/// Invalid signed 32-bit positive-overflow result from `source/*/specialize.h`.
fn i32_from_pos_overflow(specialization : Specialization) -> Int {
  match specialization {
    X86_8086SSE => -0x7FFFFFFF - 1
    RISCV => 0x7FFFFFFF
  }
}

///|
/// Invalid signed 32-bit negative-overflow result from `source/*/specialize.h`.
fn i32_from_neg_overflow(_specialization : Specialization) -> Int {
  -0x7FFFFFFF - 1
}

///|
/// Invalid signed 32-bit NaN result from `source/*/specialize.h`.
fn i32_from_nan(specialization : Specialization) -> Int {
  match specialization {
    X86_8086SSE => -0x7FFFFFFF - 1
    RISCV => 0x7FFFFFFF
  }
}

///|
/// Invalid unsigned 64-bit positive-overflow result from `source/*/specialize.h`.
fn ui64_from_pos_overflow(_specialization : Specialization) -> UInt64 {
  0xFFFFFFFFFFFFFFFFUL
}

///|
/// Invalid unsigned 64-bit negative-overflow result from `source/*/specialize.h`.
fn ui64_from_neg_overflow(specialization : Specialization) -> UInt64 {
  match specialization {
    X86_8086SSE => 0xFFFFFFFFFFFFFFFFUL
    RISCV => 0UL
  }
}

///|
/// Invalid unsigned 64-bit NaN result from `source/*/specialize.h`.
fn ui64_from_nan(_specialization : Specialization) -> UInt64 {
  0xFFFFFFFFFFFFFFFFUL
}

///|
/// Invalid signed 64-bit positive-overflow result from `source/*/specialize.h`.
fn i64_from_pos_overflow(specialization : Specialization) -> Int64 {
  match specialization {
    X86_8086SSE => -0x7FFFFFFFFFFFFFFFL - 1L
    RISCV => 0x7FFFFFFFFFFFFFFFL
  }
}

///|
/// Invalid signed 64-bit negative-overflow result from `source/*/specialize.h`.
fn i64_from_neg_overflow(_specialization : Specialization) -> Int64 {
  -0x7FFFFFFFFFFFFFFFL - 1L
}

///|
/// Invalid signed 64-bit NaN result from `source/*/specialize.h`.
fn i64_from_nan(specialization : Specialization) -> Int64 {
  match specialization {
    X86_8086SSE => -0x7FFFFFFFFFFFFFFFL - 1L
    RISCV => 0x7FFFFFFFFFFFFFFFL
  }
}

///|
/// Ports `softfloat_isSigNaNF16UI` from the selected SoftFloat specializations.
fn is_sig_nan_f16_ui(bits : UInt16) -> Bool {
  (bits & 0x7E00) == 0x7C00 && (bits & 0x01FF) != 0
}

///|
/// Ports `softfloat_isSigNaNBF16UI` from the selected SoftFloat specializations.
fn is_sig_nan_bf16_ui(bits : UInt16) -> Bool {
  (bits & 0x7FC0) == 0x7F80 && (bits & 0x003F) != 0
}

///|
/// Ports `softfloat_isSigNaNF32UI` from the selected SoftFloat specializations.
fn is_sig_nan_f32_ui(bits : UInt) -> Bool {
  (bits & 0x7FC00000U) == 0x7F800000U && (bits & 0x003FFFFFU) != 0U
}

///|
/// Ports `softfloat_isSigNaNF64UI` from the selected SoftFloat specializations.
fn is_sig_nan_f64_ui(bits : UInt64) -> Bool {
  (bits & 0x7FF8000000000000UL) == 0x7FF0000000000000UL &&
  (bits & 0x0007FFFFFFFFFFFFUL) != 0UL
}

///|
/// Returns true when this F16 bit pattern is a signaling NaN.
///
/// This is a pure classification helper. It does not quiet the NaN, does not
/// canonicalize the payload, and raises no `Invalid` flag. Non-NaN values,
/// infinities, and quiet NaNs return false.
pub fn F16::is_signaling_nan(self : F16) -> Bool {
  is_sig_nan_f16_ui(self.0)
}

///|
/// Returns true when this BF16 bit pattern is a signaling NaN.
///
/// This helper only inspects the raw exponent and fraction bits. It never
/// raises flags, so callers that need SoftFloat invalid-flag behavior should
/// use a conversion or arithmetic operation instead.
pub fn BF16::is_signaling_nan(self : BF16) -> Bool {
  is_sig_nan_bf16_ui(self.0)
}

///|
/// Returns true when this F32 bit pattern is a signaling NaN.
///
/// Quiet NaNs, infinities, zeros, subnormals, and finite numbers return false.
/// The value is not modified and no exception flags are raised.
pub fn F32::is_signaling_nan(self : F32) -> Bool {
  is_sig_nan_f32_ui(self.0)
}

///|
/// Returns true when this F64 bit pattern is a signaling NaN.
///
/// This is a bit-level predicate only: it does not quiet signaling NaNs and
/// does not raise `Invalid`.
pub fn F64::is_signaling_nan(self : F64) -> Bool {
  is_sig_nan_f64_ui(self.0)
}

///|
/// Ports `source/8086-SSE/s_f16UIToCommonNaN.c`.
///
/// RISCV uses the macro form in `source/RISCV/specialize.h`, where only the
/// invalid flag side effect matters and common-NaN payload storage is unused.
fn f16_ui_to_common_nan(
  context : Context,
  bits : UInt16,
) -> SoftResult[CommonNaN] {
  let context = if is_sig_nan_f16_ui(bits) {
    context.raise_flags(ExceptionFlags::invalid())
  } else {
    context
  }
  let value = match context.specialization {
    X86_8086SSE =>
      { sign: sign_f16_ui(bits), v64: bits.to_uint64() << 54, v0: 0UL }
    RISCV => { sign: false, v64: 0UL, v0: 0UL }
  }
  { value, context }
}

///|
/// Ports `source/8086-SSE/s_bf16UIToCommonNaN.c`.
///
/// RISCV uses the macro form in `source/RISCV/specialize.h`, where only the
/// invalid flag side effect matters and common-NaN payload storage is unused.
fn bf16_ui_to_common_nan(
  context : Context,
  bits : UInt16,
) -> SoftResult[CommonNaN] {
  let context = if is_sig_nan_bf16_ui(bits) {
    context.raise_flags(ExceptionFlags::invalid())
  } else {
    context
  }
  let value = match context.specialization {
    X86_8086SSE =>
      { sign: sign_bf16_ui(bits), v64: bits.to_uint64() << 56, v0: 0UL }
    RISCV => { sign: false, v64: 0UL, v0: 0UL }
  }
  { value, context }
}

///|
/// Ports `source/8086-SSE/s_f32UIToCommonNaN.c`.
///
/// RISCV uses the macro form in `source/RISCV/specialize.h`, where only the
/// invalid flag side effect matters and common-NaN payload storage is unused.
fn f32_ui_to_common_nan(
  context : Context,
  bits : UInt,
) -> SoftResult[CommonNaN] {
  let context = if is_sig_nan_f32_ui(bits) {
    context.raise_flags(ExceptionFlags::invalid())
  } else {
    context
  }
  let value = match context.specialization {
    X86_8086SSE =>
      { sign: sign_f32_ui(bits), v64: bits.to_uint64() << 41, v0: 0UL }
    RISCV => { sign: false, v64: 0UL, v0: 0UL }
  }
  { value, context }
}

///|
/// Ports `source/8086-SSE/s_f64UIToCommonNaN.c`.
///
/// RISCV uses the macro form in `source/RISCV/specialize.h`, where only the
/// invalid flag side effect matters and common-NaN payload storage is unused.
fn f64_ui_to_common_nan(
  context : Context,
  bits : UInt64,
) -> SoftResult[CommonNaN] {
  let context = if is_sig_nan_f64_ui(bits) {
    context.raise_flags(ExceptionFlags::invalid())
  } else {
    context
  }
  let value = match context.specialization {
    X86_8086SSE => { sign: sign_f64_ui(bits), v64: bits << 12, v0: 0UL }
    RISCV => { sign: false, v64: 0UL, v0: 0UL }
  }
  { value, context }
}

///|
/// Ports `source/8086-SSE/s_commonNaNToF16UI.c` and RISCV's default-NaN macro.
fn common_nan_to_f16_ui(context : Context, nan : CommonNaN) -> UInt16 {
  ignore(nan.v0)
  match context.specialization {
    X86_8086SSE => {
      let sign_bits : UInt16 = if nan.sign { 1 << 15 } else { 0 }
      sign_bits | 0x7E00 | (nan.v64 >> 54).to_uint16()
    }
    RISCV => default_nan_f16_ui(RISCV)
  }
}

///|
/// Ports `source/8086-SSE/s_commonNaNToBF16UI.c` and RISCV's default-NaN macro.
fn common_nan_to_bf16_ui(context : Context, nan : CommonNaN) -> UInt16 {
  ignore(nan.v0)
  match context.specialization {
    X86_8086SSE => {
      let sign_bits : UInt16 = if nan.sign { 1 << 15 } else { 0 }
      sign_bits | 0x7FC0 | (nan.v64 >> 56).to_uint16()
    }
    RISCV => default_nan_bf16_ui(RISCV)
  }
}

///|
/// Ports `source/8086-SSE/s_commonNaNToF32UI.c` and RISCV's default-NaN macro.
fn common_nan_to_f32_ui(context : Context, nan : CommonNaN) -> UInt {
  ignore(nan.v0)
  match context.specialization {
    X86_8086SSE => {
      let sign_bits = if nan.sign { 1U << 31 } else { 0U }
      sign_bits | 0x7FC00000U | (nan.v64 >> 41).to_uint()
    }
    RISCV => default_nan_f32_ui(RISCV)
  }
}

///|
/// Ports `source/8086-SSE/s_commonNaNToF64UI.c` and RISCV's default-NaN macro.
fn common_nan_to_f64_ui(context : Context, nan : CommonNaN) -> UInt64 {
  ignore(nan.v0)
  match context.specialization {
    X86_8086SSE => {
      let sign_bits = if nan.sign { 1UL << 63 } else { 0UL }
      sign_bits | 0x7FF8000000000000UL | (nan.v64 >> 12)
    }
    RISCV => default_nan_f64_ui(RISCV)
  }
}

///|
/// Ports `source/8086-SSE/s_propagateNaNF16UI.c` and
/// `source/RISCV/s_propagateNaNF16UI.c`.
fn propagate_nan_f16_ui(
  context : Context,
  a : UInt16,
  b : UInt16,
) -> SoftResult[UInt16] {
  match context.specialization {
    X86_8086SSE => {
      let a_is_sig = is_sig_nan_f16_ui(a)
      let context = if a_is_sig || is_sig_nan_f16_ui(b) {
        context.raise_flags(ExceptionFlags::invalid())
      } else {
        context
      }
      let value = if a_is_sig {
        a | 0x0200
      } else {
        (if is_nan_f16_ui(a) { a } else { b }) | 0x0200
      }
      { value, context }
    }
    RISCV => {
      let context = if is_sig_nan_f16_ui(a) || is_sig_nan_f16_ui(b) {
        context.raise_flags(ExceptionFlags::invalid())
      } else {
        context
      }
      { value: default_nan_f16_ui(RISCV), context }
    }
  }
}

///|
/// Ports `source/8086-SSE/s_propagateNaNF32UI.c` and
/// `source/RISCV/s_propagateNaNF32UI.c`.
fn propagate_nan_f32_ui(
  context : Context,
  a : UInt,
  b : UInt,
) -> SoftResult[UInt] {
  match context.specialization {
    X86_8086SSE => {
      let a_is_sig = is_sig_nan_f32_ui(a)
      let context = if a_is_sig || is_sig_nan_f32_ui(b) {
        context.raise_flags(ExceptionFlags::invalid())
      } else {
        context
      }
      let value = if a_is_sig {
        a | 0x00400000U
      } else {
        (if is_nan_f32_ui(a) { a } else { b }) | 0x00400000U
      }
      { value, context }
    }
    RISCV => {
      let context = if is_sig_nan_f32_ui(a) || is_sig_nan_f32_ui(b) {
        context.raise_flags(ExceptionFlags::invalid())
      } else {
        context
      }
      { value: default_nan_f32_ui(RISCV), context }
    }
  }
}

///|
/// Ports `source/8086-SSE/s_propagateNaNF64UI.c` and
/// `source/RISCV/s_propagateNaNF64UI.c`.
fn propagate_nan_f64_ui(
  context : Context,
  a : UInt64,
  b : UInt64,
) -> SoftResult[UInt64] {
  match context.specialization {
    X86_8086SSE => {
      let a_is_sig = is_sig_nan_f64_ui(a)
      let context = if a_is_sig || is_sig_nan_f64_ui(b) {
        context.raise_flags(ExceptionFlags::invalid())
      } else {
        context
      }
      let value = if a_is_sig {
        a | 0x0008000000000000UL
      } else {
        (if is_nan_f64_ui(a) { a } else { b }) | 0x0008000000000000UL
      }
      { value, context }
    }
    RISCV => {
      let context = if is_sig_nan_f64_ui(a) || is_sig_nan_f64_ui(b) {
        context.raise_flags(ExceptionFlags::invalid())
      } else {
        context
      }
      { value: default_nan_f64_ui(RISCV), context }
    }
  }
}
