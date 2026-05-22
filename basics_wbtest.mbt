///|
test "bit wrappers round-trip raw payloads" {
  @debug.assert_eq(F16::from_bits(0x3C00).to_bits(), 0x3C00)
  @debug.assert_eq(BF16::from_bits(0x3F80).to_bits(), 0x3F80)
  @debug.assert_eq(F32::from_bits(0x3F800000U).to_bits(), 0x3F800000U)
  @debug.assert_eq(
    F64::from_bits(0x3FF0000000000000UL).to_bits(),
    0x3FF0000000000000UL,
  )
}

///|
test "native float bridges reinterpret bits only" {
  @debug.assert_eq(
    F32::from_float_bits(Float::reinterpret_from_uint(0x3F800000U)).to_bits(),
    0x3F800000U,
  )
  @debug.assert_eq(
    F32::from_bits(0x3F800000U).to_float_bits().reinterpret_as_uint(),
    0x3F800000U,
  )
  @debug.assert_eq(
    F64::from_double_bits(0x3FF0000000000000UL.reinterpret_as_double()).to_bits(),
    0x3FF0000000000000UL,
  )
  @debug.assert_eq(
    F64::from_bits(0x3FF0000000000000UL)
    .to_double_bits()
    .reinterpret_as_uint64(),
    0x3FF0000000000000UL,
  )
}

///|
test "context defaults and flag accumulation" {
  let context = Context::default()
  @debug.assert_eq(context.rounding.softfloat_code(), 0U)
  @debug.assert_eq(context.tininess.softfloat_code(), 1U)
  @debug.assert_eq(context.flags.to_bits(), 0U)
  @debug.assert_eq(context.specialization == X86_8086SSE, true)
  let raised = context
    .raise_flags(ExceptionFlags::inexact())
    .raise_flags(ExceptionFlags::invalid())
  @debug.assert_eq(raised.flags.contains(ExceptionFlags::inexact()), true)
  @debug.assert_eq(raised.flags.contains(ExceptionFlags::invalid()), true)
  @debug.assert_eq(raised.flags.to_bits(), 17U)
  @debug.assert_eq(raised.clear_flags().flags.to_bits(), 0U)
  @debug.assert_eq(Context::riscv().specialization == RISCV, true)
}

///|
test "field helpers match softfloat masks" {
  @debug.assert_eq(sign_f16_ui(0x8000), true)
  @debug.assert_eq(exp_f16_ui(0x7C00), 0x1F)
  @debug.assert_eq(frac_f16_ui(0x03FF), 0x03FF)
  @debug.assert_eq(pack_to_f16_ui(true, 0x1F, 0x0200), 0xFE00)
  @debug.assert_eq(is_nan_f16_ui(0x7E00), true)
  @debug.assert_eq(is_nan_f16_ui(0x7C00), false)

  @debug.assert_eq(sign_bf16_ui(0x8000), true)
  @debug.assert_eq(exp_bf16_ui(0x7F80), 0xFF)
  @debug.assert_eq(frac_bf16_ui(0x007F), 0x007F)
  @debug.assert_eq(pack_to_bf16_ui(false, 0xFF, 0x0040), 0x7FC0)
  @debug.assert_eq(is_nan_bf16_ui(0x7FC0), true)
  @debug.assert_eq(is_nan_bf16_ui(0x7F80), false)

  @debug.assert_eq(sign_f32_ui(0x80000000U), true)
  @debug.assert_eq(exp_f32_ui(0x7F800000U), 0xFF)
  @debug.assert_eq(frac_f32_ui(0x007FFFFFU), 0x007FFFFFU)
  @debug.assert_eq(pack_to_f32_ui(true, 0xFF, 0x00400000U), 0xFFC00000U)
  @debug.assert_eq(is_nan_f32_ui(0x7FC00000U), true)
  @debug.assert_eq(is_nan_f32_ui(0x7F800000U), false)

  @debug.assert_eq(sign_f64_ui(0x8000000000000000UL), true)
  @debug.assert_eq(exp_f64_ui(0x7FF0000000000000UL), 0x7FF)
  @debug.assert_eq(frac_f64_ui(0x000FFFFFFFFFFFFFUL), 0x000FFFFFFFFFFFFFUL)
  @debug.assert_eq(
    pack_to_f64_ui(true, 0x7FF, 0x0008000000000000UL),
    0xFFF8000000000000UL,
  )
  @debug.assert_eq(is_nan_f64_ui(0x7FF8000000000000UL), true)
  @debug.assert_eq(is_nan_f64_ui(0x7FF0000000000000UL), false)
}

///|
test "pack helpers round-trip boundary fields" {
  let f16_neg_max = pack_to_f16_ui(true, 0x1F, 0x03FF)
  @debug.assert_eq(sign_f16_ui(f16_neg_max), true)
  @debug.assert_eq(exp_f16_ui(f16_neg_max), 0x1F)
  @debug.assert_eq(frac_f16_ui(f16_neg_max), 0x03FF)
  let f16_pos_zero = pack_to_f16_ui(false, 0, 0)
  @debug.assert_eq(sign_f16_ui(f16_pos_zero), false)
  @debug.assert_eq(exp_f16_ui(f16_pos_zero), 0)
  @debug.assert_eq(frac_f16_ui(f16_pos_zero), 0)

  let bf16_neg_max = pack_to_bf16_ui(true, 0xFF, 0x007F)
  @debug.assert_eq(sign_bf16_ui(bf16_neg_max), true)
  @debug.assert_eq(exp_bf16_ui(bf16_neg_max), 0xFF)
  @debug.assert_eq(frac_bf16_ui(bf16_neg_max), 0x007F)
  let bf16_pos_zero = pack_to_bf16_ui(false, 0, 0)
  @debug.assert_eq(sign_bf16_ui(bf16_pos_zero), false)
  @debug.assert_eq(exp_bf16_ui(bf16_pos_zero), 0)
  @debug.assert_eq(frac_bf16_ui(bf16_pos_zero), 0)

  let f32_neg_max = pack_to_f32_ui(true, 0xFF, 0x007FFFFFU)
  @debug.assert_eq(sign_f32_ui(f32_neg_max), true)
  @debug.assert_eq(exp_f32_ui(f32_neg_max), 0xFF)
  @debug.assert_eq(frac_f32_ui(f32_neg_max), 0x007FFFFFU)
  let f32_pos_zero = pack_to_f32_ui(false, 0, 0U)
  @debug.assert_eq(sign_f32_ui(f32_pos_zero), false)
  @debug.assert_eq(exp_f32_ui(f32_pos_zero), 0)
  @debug.assert_eq(frac_f32_ui(f32_pos_zero), 0U)

  let f64_neg_max = pack_to_f64_ui(true, 0x7FF, 0x000FFFFFFFFFFFFFUL)
  @debug.assert_eq(sign_f64_ui(f64_neg_max), true)
  @debug.assert_eq(exp_f64_ui(f64_neg_max), 0x7FF)
  @debug.assert_eq(frac_f64_ui(f64_neg_max), 0x000FFFFFFFFFFFFFUL)
  let f64_pos_zero = pack_to_f64_ui(false, 0, 0UL)
  @debug.assert_eq(sign_f64_ui(f64_pos_zero), false)
  @debug.assert_eq(exp_f64_ui(f64_pos_zero), 0)
  @debug.assert_eq(frac_f64_ui(f64_pos_zero), 0UL)
}

///|
test "signaling nan predicates cover payload boundaries" {
  @debug.assert_eq(F16::from_bits(0x7C01).is_signaling_nan(), true)
  @debug.assert_eq(F16::from_bits(0x7DFF).is_signaling_nan(), true)
  @debug.assert_eq(F16::from_bits(0x7E00).is_signaling_nan(), false)
  @debug.assert_eq(F16::from_bits(0x7FFF).is_signaling_nan(), false)
  @debug.assert_eq(F16::from_bits(0x7C00).is_signaling_nan(), false)

  @debug.assert_eq(BF16::from_bits(0x7F81).is_signaling_nan(), true)
  @debug.assert_eq(BF16::from_bits(0x7FBF).is_signaling_nan(), true)
  @debug.assert_eq(BF16::from_bits(0x7FC0).is_signaling_nan(), false)
  @debug.assert_eq(BF16::from_bits(0x7FFF).is_signaling_nan(), false)
  @debug.assert_eq(BF16::from_bits(0x7F80).is_signaling_nan(), false)

  @debug.assert_eq(F32::from_bits(0x7F800001U).is_signaling_nan(), true)
  @debug.assert_eq(F32::from_bits(0x7FBFFFFFU).is_signaling_nan(), true)
  @debug.assert_eq(F32::from_bits(0x7FC00000U).is_signaling_nan(), false)
  @debug.assert_eq(F32::from_bits(0x7FFFFFFFU).is_signaling_nan(), false)
  @debug.assert_eq(F32::from_bits(0x7F800000U).is_signaling_nan(), false)

  @debug.assert_eq(
    F64::from_bits(0x7FF0000000000001UL).is_signaling_nan(),
    true,
  )
  @debug.assert_eq(
    F64::from_bits(0x7FF7FFFFFFFFFFFFUL).is_signaling_nan(),
    true,
  )
  @debug.assert_eq(
    F64::from_bits(0x7FF8000000000000UL).is_signaling_nan(),
    false,
  )
  @debug.assert_eq(
    F64::from_bits(0x7FFFFFFFFFFFFFFFUL).is_signaling_nan(),
    false,
  )
  @debug.assert_eq(
    F64::from_bits(0x7FF0000000000000UL).is_signaling_nan(),
    false,
  )
}

///|
test "specialization constants match selected profiles" {
  @debug.assert_eq(default_nan_f16_ui(X86_8086SSE), 0xFE00)
  @debug.assert_eq(default_nan_f16_ui(RISCV), 0x7E00)
  @debug.assert_eq(default_nan_bf16_ui(RISCV), 0x7FC0)
  @debug.assert_eq(default_nan_f32_ui(X86_8086SSE), 0xFFC00000U)
  @debug.assert_eq(default_nan_f32_ui(RISCV), 0x7FC00000U)
  @debug.assert_eq(default_nan_f64_ui(X86_8086SSE), 0xFFF8000000000000UL)
  @debug.assert_eq(default_nan_f64_ui(RISCV), 0x7FF8000000000000UL)

  @debug.assert_eq(ui32_from_pos_overflow(X86_8086SSE), 0xFFFFFFFFU)
  @debug.assert_eq(ui32_from_neg_overflow(X86_8086SSE), 0xFFFFFFFFU)
  @debug.assert_eq(ui32_from_neg_overflow(RISCV), 0U)
  @debug.assert_eq(ui32_from_nan(RISCV), 0xFFFFFFFFU)
  @debug.assert_eq(i32_from_pos_overflow(X86_8086SSE), -0x7FFFFFFF - 1)
  @debug.assert_eq(i32_from_pos_overflow(RISCV), 0x7FFFFFFF)
  @debug.assert_eq(i32_from_neg_overflow(RISCV), -0x7FFFFFFF - 1)
  @debug.assert_eq(i32_from_nan(RISCV), 0x7FFFFFFF)

  @debug.assert_eq(ui64_from_pos_overflow(X86_8086SSE), 0xFFFFFFFFFFFFFFFFUL)
  @debug.assert_eq(ui64_from_neg_overflow(X86_8086SSE), 0xFFFFFFFFFFFFFFFFUL)
  @debug.assert_eq(ui64_from_neg_overflow(RISCV), 0UL)
  @debug.assert_eq(ui64_from_nan(RISCV), 0xFFFFFFFFFFFFFFFFUL)
  @debug.assert_eq(
    i64_from_pos_overflow(X86_8086SSE),
    -0x7FFFFFFFFFFFFFFFL - 1L,
  )
  @debug.assert_eq(i64_from_pos_overflow(RISCV), 0x7FFFFFFFFFFFFFFFL)
  @debug.assert_eq(i64_from_neg_overflow(RISCV), -0x7FFFFFFFFFFFFFFFL - 1L)
  @debug.assert_eq(i64_from_nan(RISCV), 0x7FFFFFFFFFFFFFFFL)
}

///|
test "common nan conversion and propagation are specialization aware" {
  let x86 = Context::default()
  let riscv = Context::riscv()

  let f16_common = f16_ui_to_common_nan(x86, 0xFE01)
  @debug.assert_eq(
    common_nan_to_f16_ui(f16_common.context, f16_common.value),
    0xFE01,
  )
  let f16_sig = f16_ui_to_common_nan(x86, 0x7C01)
  @debug.assert_eq(
    f16_sig.context.flags.contains(ExceptionFlags::invalid()),
    true,
  )
  @debug.assert_eq(common_nan_to_f16_ui(riscv, f16_sig.value), 0x7E00)
  let f16_prop_x86 = propagate_nan_f16_ui(x86, 0x7C01, 0x7E02)
  @debug.assert_eq(f16_prop_x86.value, 0x7E01)
  @debug.assert_eq(
    f16_prop_x86.context.flags.contains(ExceptionFlags::invalid()),
    true,
  )
  let f16_prop_x86_b_sig = propagate_nan_f16_ui(x86, 0x7E02, 0x7C01)
  @debug.assert_eq(f16_prop_x86_b_sig.value, 0x7E02)
  @debug.assert_eq(
    f16_prop_x86_b_sig.context.flags.contains(ExceptionFlags::invalid()),
    true,
  )
  let f16_prop_x86_b_nan = propagate_nan_f16_ui(x86, 0x3C00, 0x7E02)
  @debug.assert_eq(f16_prop_x86_b_nan.value, 0x7E02)
  @debug.assert_eq(
    f16_prop_x86_b_nan.context.flags.contains(ExceptionFlags::invalid()),
    false,
  )
  let f16_prop_riscv = propagate_nan_f16_ui(riscv, 0x7C01, 0x7E02)
  @debug.assert_eq(f16_prop_riscv.value, 0x7E00)
  @debug.assert_eq(
    f16_prop_riscv.context.flags.contains(ExceptionFlags::invalid()),
    true,
  )

  let bf16_common = bf16_ui_to_common_nan(x86, 0xFFC1)
  @debug.assert_eq(
    common_nan_to_bf16_ui(bf16_common.context, bf16_common.value),
    0xFFC1,
  )
  @debug.assert_eq(common_nan_to_bf16_ui(riscv, bf16_common.value), 0x7FC0)

  let f32_common = f32_ui_to_common_nan(x86, 0xFFC00001U)
  @debug.assert_eq(
    common_nan_to_f32_ui(f32_common.context, f32_common.value),
    0xFFC00001U,
  )
  @debug.assert_eq(common_nan_to_f32_ui(riscv, f32_common.value), 0x7FC00000U)
  let f32_prop_x86 = propagate_nan_f32_ui(x86, 0x7F800001U, 0x7FC00002U)
  @debug.assert_eq(f32_prop_x86.value, 0x7FC00001U)
  @debug.assert_eq(
    f32_prop_x86.context.flags.contains(ExceptionFlags::invalid()),
    true,
  )
  let f32_prop_riscv = propagate_nan_f32_ui(riscv, 0x7F800001U, 0x7FC00002U)
  @debug.assert_eq(f32_prop_riscv.value, 0x7FC00000U)
  @debug.assert_eq(
    f32_prop_riscv.context.flags.contains(ExceptionFlags::invalid()),
    true,
  )

  let f64_common = f64_ui_to_common_nan(x86, 0xFFF8000000000001UL)
  @debug.assert_eq(
    common_nan_to_f64_ui(f64_common.context, f64_common.value),
    0xFFF8000000000001UL,
  )
  @debug.assert_eq(
    common_nan_to_f64_ui(riscv, f64_common.value),
    0x7FF8000000000000UL,
  )
  let f64_prop_x86 = propagate_nan_f64_ui(
    x86, 0x7FF0000000000001UL, 0x7FF8000000000002UL,
  )
  @debug.assert_eq(f64_prop_x86.value, 0x7FF8000000000001UL)
  @debug.assert_eq(
    f64_prop_x86.context.flags.contains(ExceptionFlags::invalid()),
    true,
  )
  let f64_prop_riscv = propagate_nan_f64_ui(
    riscv, 0x7FF0000000000001UL, 0x7FF8000000000002UL,
  )
  @debug.assert_eq(f64_prop_riscv.value, 0x7FF8000000000000UL)
  @debug.assert_eq(
    f64_prop_riscv.context.flags.contains(ExceptionFlags::invalid()),
    true,
  )
}
