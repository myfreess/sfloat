///|
test "f32_to_f16 and f32_to_f64 convert finite and special values" {
  let context = Context::default()
  let one16 = f32_to_f16(context, F32::from_bits(0x3F800000U))
  @debug.assert_eq(one16.value.to_bits(), 0x3C00)
  assert_flags(one16.context, 0U)
  let neg_zero16 = F32::from_bits(0x80000000U).to_f16(context)
  @debug.assert_eq(neg_zero16.value.to_bits(), 0x8000)
  let overflow16 = f32_to_f16(context, F32::from_bits(0x47800000U))
  @debug.assert_eq(overflow16.value.to_bits(), 0x7C00)
  assert_flags(
    overflow16.context,
    ExceptionFlags::overflow().merge(ExceptionFlags::inexact()).to_bits(),
  )

  let one64 = F32::from_bits(0x3F800000U).to_f64(context)
  @debug.assert_eq(one64.value.to_bits(), 0x3FF0000000000000UL)
  assert_flags(one64.context, 0U)
  let sub64 = F32::from_bits(0x00000001U).to_f64(context)
  @debug.assert_eq(sub64.value.to_bits(), 0x36A0000000000000UL)
  let inf64 = f32_to_f64(context, F32::from_bits(0xFF800000U))
  @debug.assert_eq(inf64.value.to_bits(), 0xFFF0000000000000UL)
}

///|
test "f32 conversions propagate nan by specialization" {
  let context = Context::default()
  let x86_16 = f32_to_f16(context, F32::from_bits(0x7F800001U))
  @debug.assert_eq(x86_16.value.to_bits(), 0x7E00)
  assert_flags(x86_16.context, ExceptionFlags::invalid().to_bits())
  let riscv_64 = f32_to_f64(Context::riscv(), F32::from_bits(0x7F800001U))
  @debug.assert_eq(riscv_64.value.to_bits(), 0x7FF8000000000000UL)
  assert_flags(riscv_64.context, ExceptionFlags::invalid().to_bits())
  @debug.assert_eq(f32_is_signaling_nan(F32::from_bits(0x7F800001U)), true)
}

///|
test "f32 integer conversions honor rounding and invalid constants" {
  let context = Context::default()
  let one = F32::from_bits(0x3F800000U)
  @debug.assert_eq(f32_to_ui32(context, one, NearEven, true).value, 1U)
  @debug.assert_eq(f32_to_ui64(context, one, NearEven, true).value, 1UL)
  @debug.assert_eq(f32_to_i32(context, one, NearEven, true).value, 1)
  @debug.assert_eq(f32_to_i64(context, one, NearEven, true).value, 1L)

  let one_half = F32::from_bits(0x3FC00000U)
  let near = one_half.to_ui32(context, NearEven, true)
  @debug.assert_eq(near.value, 2U)
  assert_flags(near.context, ExceptionFlags::inexact().to_bits())
  @debug.assert_eq(one_half.to_ui32(context, MinMag, true).value, 1U)
  @debug.assert_eq(one_half.to_ui32(context, Max, true).value, 2U)
  @debug.assert_eq(one_half.to_ui32(context, Odd, true).value, 1U)

  let neg = F32::from_bits(0xBFC00000U)
  @debug.assert_eq(neg.to_i32(context, Min, true).value, -2)
  @debug.assert_eq(neg.to_i32(context, Max, true).value, -1)
  @debug.assert_eq(neg.to_i64(context, Odd, true).value, -1L)

  let neg_ui = F32::from_bits(0xBF800000U).to_ui32(
    Context::riscv(),
    NearEven,
    true,
  )
  @debug.assert_eq(neg_ui.value, 0U)
  assert_flags(neg_ui.context, ExceptionFlags::invalid().to_bits())
  let nan_i64 = F32::from_bits(0x7FC00000U).to_i64(context, NearEven, true)
  @debug.assert_eq(nan_i64.value, -0x7FFFFFFFFFFFFFFFL - 1L)
  assert_flags(nan_i64.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f32 minMag integer conversions truncate and flag inexact" {
  let context = Context::default()
  let one_half = F32::from_bits(0x3FC00000U)
  let ui32 = f32_to_ui32_min_mag(context, one_half, true)
  @debug.assert_eq(ui32.value, 1U)
  assert_flags(ui32.context, ExceptionFlags::inexact().to_bits())
  @debug.assert_eq(f32_to_ui64_min_mag(context, one_half, true).value, 1UL)

  let neg = F32::from_bits(0xBFC00000U)
  let i32 = f32_to_i32_min_mag(context, neg, true)
  @debug.assert_eq(i32.value, -1)
  assert_flags(i32.context, ExceptionFlags::inexact().to_bits())
  @debug.assert_eq(f32_to_i64_min_mag(context, neg, true).value, -1L)

  let min_i32 = f32_to_i32_min_mag(context, F32::from_bits(0xCF000000U), true)
  @debug.assert_eq(min_i32.value, -0x7FFFFFFF - 1)
  assert_flags(min_i32.context, 0U)
  let pos_i64_overflow = f32_to_i64_min_mag(
    context,
    F32::from_bits(0x5F000000U),
    true,
  )
  @debug.assert_eq(pos_i64_overflow.value, -0x7FFFFFFFFFFFFFFFL - 1L)
  assert_flags(pos_i64_overflow.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f32_round_to_int handles tiny middle and nan cases" {
  let context = Context::default()
  let half = F32::from_bits(0x3F000000U)
  let near_even = f32_round_to_int(context, half, NearEven, true)
  @debug.assert_eq(near_even.value.to_bits(), 0x00000000U)
  assert_flags(near_even.context, ExceptionFlags::inexact().to_bits())
  @debug.assert_eq(
    f32_round_to_int(context, half, NearMaxMag, true).value.to_bits(),
    0x3F800000U,
  )
  let one_half = F32::from_bits(0x3FC00000U)
  @debug.assert_eq(
    one_half.round_to_int(context, NearEven, true).value.to_bits(),
    0x40000000U,
  )
  @debug.assert_eq(
    f32_round_to_int(context, one_half, MinMag, true).value.to_bits(),
    0x3F800000U,
  )
  let quiet = f32_round_to_int(context, one_half, NearEven, false)
  @debug.assert_eq(quiet.value.to_bits(), 0x40000000U)
  assert_flags(quiet.context, 0U)
  let signaling_nan = f32_round_to_int(
    context,
    F32::from_bits(0x7F800001U),
    NearEven,
    true,
  )
  @debug.assert_eq(signaling_nan.value.to_bits(), 0x7FC00001U)
  assert_flags(signaling_nan.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f32_add and f32_sub cover exact sums epsilon and specials" {
  let context = Context::default()
  let one = F32::from_bits(0x3F800000U)
  let two = f32_add(context, one, one)
  @debug.assert_eq(two.value.to_bits(), 0x40000000U)
  assert_flags(two.context, 0U)

  let tiny = F32::from_bits(0x00000001U)
  let near = f32_add(context, one, tiny)
  @debug.assert_eq(near.value.to_bits(), 0x3F800000U)
  assert_flags(near.context, ExceptionFlags::inexact().to_bits())
  let up = f32_add(context.with_rounding(Max), one, tiny)
  @debug.assert_eq(up.value.to_bits(), 0x3F800001U)
  assert_flags(up.context, ExceptionFlags::inexact().to_bits())

  let invalid = f32_add(
    context,
    F32::from_bits(0x7F800000U),
    F32::from_bits(0xFF800000U),
  )
  @debug.assert_eq(invalid.value.to_bits(), 0xFFC00000U)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())
  let zero = f32_sub(context, one, one)
  @debug.assert_eq(zero.value.to_bits(), 0x00000000U)
  let min_zero = f32_sub(context.with_rounding(Min), one, one)
  @debug.assert_eq(min_zero.value.to_bits(), 0x80000000U)
  let two_minus_one = F32::from_bits(0x40000000U).sub(context, one)
  @debug.assert_eq(two_minus_one.value.to_bits(), 0x3F800000U)
}

///|
test "f32_mul covers finite signs subnormals and special cases" {
  let context = Context::default()
  let one = F32::from_bits(0x3F800000U)
  let two = F32::from_bits(0x40000000U)
  let product = one.mul(context, two)
  @debug.assert_eq(product.value.to_bits(), 0x40000000U)
  assert_flags(product.context, 0U)

  let neg = f32_mul(context, F32::from_bits(0xBF800000U), two)
  @debug.assert_eq(neg.value.to_bits(), 0xC0000000U)
  let quarter = f32_mul(
    context,
    F32::from_bits(0x3F000000U),
    F32::from_bits(0x3F000000U),
  )
  @debug.assert_eq(quarter.value.to_bits(), 0x3E800000U)
  let tiny_times_two = f32_mul(context, F32::from_bits(0x00000001U), two)
  @debug.assert_eq(tiny_times_two.value.to_bits(), 0x00000002U)
  assert_flags(tiny_times_two.context, 0U)

  let invalid = f32_mul(
    context,
    F32::from_bits(0x00000000U),
    F32::from_bits(0x7F800000U),
  )
  @debug.assert_eq(invalid.value.to_bits(), 0xFFC00000U)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())
  let inf = f32_mul(
    context,
    F32::from_bits(0xFF800000U),
    F32::from_bits(0x40000000U),
  )
  @debug.assert_eq(inf.value.to_bits(), 0xFF800000U)
  let nan = f32_mul(context, F32::from_bits(0x7F800001U), one)
  @debug.assert_eq(nan.value.to_bits(), 0x7FC00001U)
  assert_flags(nan.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f32_div covers exact quotient inexact and exceptional cases" {
  let context = Context::default()
  let one = F32::from_bits(0x3F800000U)
  let two = F32::from_bits(0x40000000U)
  let half = f32_div(context, one, two)
  @debug.assert_eq(half.value.to_bits(), 0x3F000000U)
  assert_flags(half.context, 0U)
  let neg_half = F32::from_bits(0xBF800000U).div(context, two)
  @debug.assert_eq(neg_half.value.to_bits(), 0xBF000000U)
  let third = f32_div(context, one, F32::from_bits(0x40400000U))
  @debug.assert_eq(third.value.to_bits(), 0x3EAAAAABU)
  assert_flags(third.context, ExceptionFlags::inexact().to_bits())

  let inf = f32_div(context, one, F32::from_bits(0x00000000U))
  @debug.assert_eq(inf.value.to_bits(), 0x7F800000U)
  assert_flags(inf.context, ExceptionFlags::infinite().to_bits())
  let invalid = f32_div(
    context,
    F32::from_bits(0x00000000U),
    F32::from_bits(0x00000000U),
  )
  @debug.assert_eq(invalid.value.to_bits(), 0xFFC00000U)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())
  let finite_over_inf = f32_div(context, one, F32::from_bits(0x7F800000U))
  @debug.assert_eq(finite_over_inf.value.to_bits(), 0x00000000U)
  let nan = f32_div(context, F32::from_bits(0x7F800001U), one)
  @debug.assert_eq(nan.value.to_bits(), 0x7FC00001U)
  assert_flags(nan.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f32_sqrt covers exact roots inexact and invalid negatives" {
  let context = Context::default()
  let four = F32::from_bits(0x40800000U)
  let two = f32_sqrt(context, four)
  @debug.assert_eq(two.value.to_bits(), 0x40000000U)
  assert_flags(two.context, 0U)
  let half = F32::from_bits(0x3E800000U).sqrt(context)
  @debug.assert_eq(half.value.to_bits(), 0x3F000000U)
  assert_flags(half.context, 0U)

  let sqrt_two = f32_sqrt(context, F32::from_bits(0x40000000U))
  @debug.assert_eq(sqrt_two.value.to_bits(), 0x3FB504F3U)
  assert_flags(sqrt_two.context, ExceptionFlags::inexact().to_bits())
  let neg_zero = f32_sqrt(context, F32::from_bits(0x80000000U))
  @debug.assert_eq(neg_zero.value.to_bits(), 0x80000000U)
  let invalid = f32_sqrt(context, F32::from_bits(0xBF800000U))
  @debug.assert_eq(invalid.value.to_bits(), 0xFFC00000U)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())
  let inf = f32_sqrt(context, F32::from_bits(0x7F800000U))
  @debug.assert_eq(inf.value.to_bits(), 0x7F800000U)
  let nan = f32_sqrt(context, F32::from_bits(0x7F800001U))
  @debug.assert_eq(nan.value.to_bits(), 0x7FC00001U)
  assert_flags(nan.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f32_rem follows IEEE nearest-even remainder and specials" {
  let context = Context::default()
  let five = F32::from_bits(0x40A00000U)
  let two = F32::from_bits(0x40000000U)
  let rem = f32_rem(context, five, two)
  @debug.assert_eq(rem.value.to_bits(), 0x3F800000U)
  assert_flags(rem.context, 0U)

  let seven = F32::from_bits(0x40E00000U)
  let tie = seven.rem(context, two)
  @debug.assert_eq(tie.value.to_bits(), 0xBF800000U)
  let small = f32_rem(
    context,
    F32::from_bits(0x3F800000U),
    F32::from_bits(0x40800000U),
  )
  @debug.assert_eq(small.value.to_bits(), 0x3F800000U)

  let by_inf = f32_rem(
    context,
    F32::from_bits(0xBF800000U),
    F32::from_bits(0x7F800000U),
  )
  @debug.assert_eq(by_inf.value.to_bits(), 0xBF800000U)
  let invalid = f32_rem(context, F32::from_bits(0x7F800000U), two)
  @debug.assert_eq(invalid.value.to_bits(), 0xFFC00000U)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())
  let zero_divisor = f32_rem(
    context,
    F32::from_bits(0x3F800000U),
    F32::from_bits(0x00000000U),
  )
  @debug.assert_eq(zero_divisor.value.to_bits(), 0xFFC00000U)
  assert_flags(zero_divisor.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f32_mul_add fuses finite arithmetic and handles special products" {
  let context = Context::default()
  let one = F32::from_bits(0x3F800000U)
  let two = F32::from_bits(0x40000000U)
  let three = F32::from_bits(0x40400000U)
  let fused = f32_mul_add(context, two, three, one)
  @debug.assert_eq(fused.value.to_bits(), 0x40E00000U)
  assert_flags(fused.context, 0U)

  let cancel = f32_mul_add(context, one, one, F32::from_bits(0xBF800000U))
  @debug.assert_eq(cancel.value.to_bits(), 0x00000000U)
  let min_cancel = f32_mul_add(
    context.with_rounding(Min),
    one,
    one,
    F32::from_bits(0xBF800000U),
  )
  @debug.assert_eq(min_cancel.value.to_bits(), 0x80000000U)

  let tiny = F32::from_bits(0x00000001U)
  let near = one.mul_add(context, one, tiny)
  @debug.assert_eq(near.value.to_bits(), 0x3F800000U)
  assert_flags(near.context, ExceptionFlags::inexact().to_bits())
  let up = f32_mul_add(context.with_rounding(Max), one, one, tiny)
  @debug.assert_eq(up.value.to_bits(), 0x3F800001U)
  assert_flags(up.context, ExceptionFlags::inexact().to_bits())

  let invalid_prod = f32_mul_add(
    context,
    F32::from_bits(0x7F800000U),
    F32::from_bits(0x00000000U),
    one,
  )
  @debug.assert_eq(invalid_prod.value.to_bits(), 0xFFC00000U)
  assert_flags(invalid_prod.context, ExceptionFlags::invalid().to_bits())
  let invalid_sum = f32_mul_add(
    context,
    F32::from_bits(0x7F800000U),
    one,
    F32::from_bits(0xFF800000U),
  )
  @debug.assert_eq(invalid_sum.value.to_bits(), 0xFFC00000U)
  assert_flags(invalid_sum.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f32 comparisons handle ordering signed zeros and nan invalid flags" {
  let context = Context::default()
  let neg_zero = F32::from_bits(0x80000000U)
  let pos_zero = F32::from_bits(0x00000000U)
  let one = F32::from_bits(0x3F800000U)
  let two = F32::from_bits(0x40000000U)
  let neg_one = F32::from_bits(0xBF800000U)

  @debug.assert_eq(f32_eq(context, neg_zero, pos_zero).value, true)
  @debug.assert_eq(f32_lt(context, one, two).value, true)
  @debug.assert_eq(f32_le(context, two, one).value, false)
  @debug.assert_eq(f32_lt(context, neg_one, pos_zero).value, true)
  @debug.assert_eq(f32_le_quiet(context, neg_zero, pos_zero).value, true)

  let qnan = F32::from_bits(0x7FC00000U)
  let snan = F32::from_bits(0x7F800001U)
  let quiet_eq = f32_eq(context, qnan, one)
  @debug.assert_eq(quiet_eq.value, false)
  assert_flags(quiet_eq.context, 0U)
  let signaling_eq = f32_eq_signaling(context, qnan, one)
  @debug.assert_eq(signaling_eq.value, false)
  assert_flags(signaling_eq.context, ExceptionFlags::invalid().to_bits())
  let quiet_le_snan = f32_le_quiet(context, snan, one)
  @debug.assert_eq(quiet_le_snan.value, false)
  assert_flags(quiet_le_snan.context, ExceptionFlags::invalid().to_bits())
  let le_qnan = f32_le(context, qnan, one)
  @debug.assert_eq(le_qnan.value, false)
  assert_flags(le_qnan.context, ExceptionFlags::invalid().to_bits())
}
