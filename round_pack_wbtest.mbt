///|
test "norm_subnormal helpers match softfloat shift formulas" {
  let f16_min = norm_subnormal_f16_sig(0x0001)
  @debug.assert_eq(f16_min.exp, -9)
  @debug.assert_eq(f16_min.sig, 0x0400)
  let f16_max = norm_subnormal_f16_sig(0x03FF)
  @debug.assert_eq(f16_max.exp, 0)
  @debug.assert_eq(f16_max.sig, 0x07FE)

  let bf16_min = norm_subnormal_bf16_sig(0x0001)
  @debug.assert_eq(bf16_min.exp, -6)
  @debug.assert_eq(bf16_min.sig, 0x0080)
  let bf16_max = norm_subnormal_bf16_sig(0x007F)
  @debug.assert_eq(bf16_max.exp, 0)
  @debug.assert_eq(bf16_max.sig, 0x00FE)

  let f32_min = norm_subnormal_f32_sig(0x00000001U)
  @debug.assert_eq(f32_min.exp, -22)
  @debug.assert_eq(f32_min.sig, 0x00800000U)
  let f32_max = norm_subnormal_f32_sig(0x007FFFFFU)
  @debug.assert_eq(f32_max.exp, 0)
  @debug.assert_eq(f32_max.sig, 0x00FFFFFEU)

  let f64_min = norm_subnormal_f64_sig(0x0000000000000001UL)
  @debug.assert_eq(f64_min.exp, -51)
  @debug.assert_eq(f64_min.sig, 0x0010000000000000UL)
  let f64_max = norm_subnormal_f64_sig(0x000FFFFFFFFFFFFFUL)
  @debug.assert_eq(f64_max.exp, 0)
  @debug.assert_eq(f64_max.sig, 0x001FFFFFFFFFFFFEUL)
}

///|
test "round_pack_to_f16 covers ties odd underflow and overflow" {
  let context = Context::default()
  @debug.assert_eq(
    round_pack_to_f16(context, false, 14, 0x4008U).value.to_bits(),
    0x3C00,
  )
  @debug.assert_eq(
    round_pack_to_f16(context.with_rounding(NearMaxMag), false, 14, 0x4008U).value.to_bits(),
    0x3C01,
  )
  let odd = round_pack_to_f16(context.with_rounding(Odd), false, 14, 0x4001U)
  @debug.assert_eq(odd.value.to_bits(), 0x3C01)
  assert_flags(odd.context, ExceptionFlags::inexact().to_bits())

  let after = round_pack_to_f16(context, false, -1, 0x7FF8U)
  @debug.assert_eq(after.value.to_bits(), 0x0400)
  assert_flags(after.context, ExceptionFlags::inexact().to_bits())
  let before = round_pack_to_f16(
    context.with_tininess(BeforeRounding),
    false,
    -1,
    0x7FF8U,
  )
  @debug.assert_eq(before.value.to_bits(), 0x0400)
  assert_flags(
    before.context,
    ExceptionFlags::underflow().merge(ExceptionFlags::inexact()).to_bits(),
  )

  let overflow = round_pack_to_f16(context, false, 0x1E, 0x7FF8U)
  @debug.assert_eq(overflow.value.to_bits(), 0x7C00)
  assert_flags(
    overflow.context,
    ExceptionFlags::overflow().merge(ExceptionFlags::inexact()).to_bits(),
  )
  let finite_overflow = round_pack_to_f16(
    context.with_rounding(MinMag),
    false,
    0x1E,
    0x7FF8U,
  )
  @debug.assert_eq(finite_overflow.value.to_bits(), 0x7BFF)
}

///|
test "round_pack_to_bf16_f32_f64 pack exact and overflow cases" {
  let context = Context::default()
  @debug.assert_eq(
    round_pack_to_bf16(context, false, 126, 0x4000U).value.to_bits(),
    0x3F80,
  )
  @debug.assert_eq(
    round_pack_to_f32(context, false, 126, 0x40000000U).value.to_bits(),
    0x3F800000U,
  )
  @debug.assert_eq(
    round_pack_to_f64(context, false, 1022, 0x4000000000000000UL).value.to_bits(),
    0x3FF0000000000000UL,
  )
  let bf16_overflow = round_pack_to_bf16(
    context.with_rounding(MinMag),
    false,
    0xFE,
    0x7FC0U,
  )
  @debug.assert_eq(bf16_overflow.value.to_bits(), 0x7F7F)
  assert_flags(
    bf16_overflow.context,
    ExceptionFlags::overflow().merge(ExceptionFlags::inexact()).to_bits(),
  )
  let f32_overflow = round_pack_to_f32(context, false, 0xFE, 0x7FFFFFC0U)
  @debug.assert_eq(f32_overflow.value.to_bits(), 0x7F800000U)
  let f64_overflow = round_pack_to_f64(
    context, false, 0x7FE, 0x7FFFFFFFFFFFFE00UL,
  )
  @debug.assert_eq(f64_overflow.value.to_bits(), 0x7FF0000000000000UL)
}

///|
test "norm_round_pack helpers use fast exact path" {
  let context = Context::default()
  @debug.assert_eq(
    norm_round_pack_to_f16(context, false, 18, 0x0400U).value.to_bits(),
    0x3C00,
  )
  @debug.assert_eq(
    norm_round_pack_to_f32(context, false, 133, 0x00800000U).value.to_bits(),
    0x3F800000U,
  )
  @debug.assert_eq(
    norm_round_pack_to_f64(context, false, 1032, 0x0010000000000000UL).value.to_bits(),
    0x3FF0000000000000UL,
  )
}
