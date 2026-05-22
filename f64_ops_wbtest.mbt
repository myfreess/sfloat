///|
test "f64_to_f16 and f64_to_f32 convert finite and special values" {
  let context = Context::default()
  let one = F64::from_bits(0x3FF0000000000000UL)
  let one16 = f64_to_f16(context, one)
  @debug.assert_eq(one16.value.to_bits(), 0x3C00)
  assert_flags(one16.context, 0U)
  let one32 = one.to_f32(context)
  @debug.assert_eq(one32.value.to_bits(), 0x3F800000U)
  assert_flags(one32.context, 0U)

  let neg_zero16 = F64::from_bits(0x8000000000000000UL).to_f16(context)
  @debug.assert_eq(neg_zero16.value.to_bits(), 0x8000)
  let neg_zero32 = f64_to_f32(context, F64::from_bits(0x8000000000000000UL))
  @debug.assert_eq(neg_zero32.value.to_bits(), 0x80000000U)
  let overflow16 = f64_to_f16(context, F64::from_bits(0x40F0000000000000UL))
  @debug.assert_eq(overflow16.value.to_bits(), 0x7C00)
  assert_flags(
    overflow16.context,
    ExceptionFlags::overflow().merge(ExceptionFlags::inexact()).to_bits(),
  )

  let inf32 = f64_to_f32(context, F64::from_bits(0xFFF0000000000000UL))
  @debug.assert_eq(inf32.value.to_bits(), 0xFF800000U)
  assert_flags(inf32.context, 0U)
}

///|
test "f64 conversions propagate nan by specialization" {
  let context = Context::default()
  let x86_32 = f64_to_f32(context, F64::from_bits(0x7FF0000000000001UL))
  @debug.assert_eq(x86_32.value.to_bits(), 0x7FC00000U)
  assert_flags(x86_32.context, ExceptionFlags::invalid().to_bits())
  let riscv_16 = f64_to_f16(
    Context::riscv(),
    F64::from_bits(0x7FF0000000000001UL),
  )
  @debug.assert_eq(riscv_16.value.to_bits(), 0x7E00)
  assert_flags(riscv_16.context, ExceptionFlags::invalid().to_bits())
  @debug.assert_eq(
    f64_is_signaling_nan(F64::from_bits(0x7FF0000000000001UL)),
    true,
  )
}

///|
test "f64 integer conversions honor rounding and invalid constants" {
  let context = Context::default()
  let one = F64::from_bits(0x3FF0000000000000UL)
  @debug.assert_eq(f64_to_ui32(context, one, NearEven, true).value, 1U)
  @debug.assert_eq(f64_to_ui64(context, one, NearEven, true).value, 1UL)
  @debug.assert_eq(f64_to_i32(context, one, NearEven, true).value, 1)
  @debug.assert_eq(f64_to_i64(context, one, NearEven, true).value, 1L)

  let one_half = F64::from_bits(0x3FF8000000000000UL)
  let near = one_half.to_ui32(context, NearEven, true)
  @debug.assert_eq(near.value, 2U)
  assert_flags(near.context, ExceptionFlags::inexact().to_bits())
  @debug.assert_eq(one_half.to_ui32(context, MinMag, true).value, 1U)
  @debug.assert_eq(one_half.to_ui32(context, Max, true).value, 2U)
  @debug.assert_eq(one_half.to_ui32(context, Odd, true).value, 1U)

  let neg = F64::from_bits(0xBFF8000000000000UL)
  @debug.assert_eq(neg.to_i32(context, Min, true).value, -2)
  @debug.assert_eq(neg.to_i32(context, Max, true).value, -1)
  @debug.assert_eq(neg.to_i64(context, Odd, true).value, -1L)

  let neg_ui = F64::from_bits(0xBFF0000000000000UL).to_ui32(
    Context::riscv(),
    NearEven,
    true,
  )
  @debug.assert_eq(neg_ui.value, 0U)
  assert_flags(neg_ui.context, ExceptionFlags::invalid().to_bits())
  let nan_i64 = F64::from_bits(0x7FF8000000000000UL).to_i64(
    context,
    NearEven,
    true,
  )
  @debug.assert_eq(nan_i64.value, -0x7FFFFFFFFFFFFFFFL - 1L)
  assert_flags(nan_i64.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f64 minMag integer conversions truncate and flag inexact" {
  let context = Context::default()
  let one_half = F64::from_bits(0x3FF8000000000000UL)
  let ui32 = f64_to_ui32_min_mag(context, one_half, true)
  @debug.assert_eq(ui32.value, 1U)
  assert_flags(ui32.context, ExceptionFlags::inexact().to_bits())
  @debug.assert_eq(f64_to_ui64_min_mag(context, one_half, true).value, 1UL)

  let neg = F64::from_bits(0xBFF8000000000000UL)
  let i32 = f64_to_i32_min_mag(context, neg, true)
  @debug.assert_eq(i32.value, -1)
  assert_flags(i32.context, ExceptionFlags::inexact().to_bits())
  @debug.assert_eq(f64_to_i64_min_mag(context, neg, true).value, -1L)

  let min_i32 = f64_to_i32_min_mag(
    context,
    F64::from_bits(0xC1E0000000000000UL),
    true,
  )
  @debug.assert_eq(min_i32.value, -0x7FFFFFFF - 1)
  assert_flags(min_i32.context, 0U)
  let pos_i64_overflow = f64_to_i64_min_mag(
    context,
    F64::from_bits(0x43E0000000000000UL),
    true,
  )
  @debug.assert_eq(pos_i64_overflow.value, -0x7FFFFFFFFFFFFFFFL - 1L)
  assert_flags(pos_i64_overflow.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f64_round_to_int handles tiny middle and nan cases" {
  let context = Context::default()
  let half = F64::from_bits(0x3FE0000000000000UL)
  let near_even = f64_round_to_int(context, half, NearEven, true)
  @debug.assert_eq(near_even.value.to_bits(), 0x0000000000000000UL)
  assert_flags(near_even.context, ExceptionFlags::inexact().to_bits())
  @debug.assert_eq(
    f64_round_to_int(context, half, NearMaxMag, true).value.to_bits(),
    0x3FF0000000000000UL,
  )

  let one_half = F64::from_bits(0x3FF8000000000000UL)
  @debug.assert_eq(
    one_half.round_to_int(context, NearEven, true).value.to_bits(),
    0x4000000000000000UL,
  )
  @debug.assert_eq(
    f64_round_to_int(context, one_half, MinMag, true).value.to_bits(),
    0x3FF0000000000000UL,
  )
  let quiet = f64_round_to_int(context, one_half, NearEven, false)
  @debug.assert_eq(quiet.value.to_bits(), 0x4000000000000000UL)
  assert_flags(quiet.context, 0U)

  let signaling_nan = f64_round_to_int(
    context,
    F64::from_bits(0x7FF0000000000001UL),
    NearEven,
    true,
  )
  @debug.assert_eq(signaling_nan.value.to_bits(), 0x7FF8000000000001UL)
  assert_flags(signaling_nan.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f64 comparisons handle zeros ordering and nan invalid flags" {
  let context = Context::default()
  let neg_zero = F64::from_bits(0x8000000000000000UL)
  let pos_zero = F64::from_bits(0x0000000000000000UL)
  let one = F64::from_bits(0x3FF0000000000000UL)
  let two = F64::from_bits(0x4000000000000000UL)
  let neg_one = F64::from_bits(0xBFF0000000000000UL)
  @debug.assert_eq(f64_eq(context, neg_zero, pos_zero).value, true)
  @debug.assert_eq(f64_lt(context, one, two).value, true)
  @debug.assert_eq(f64_le(context, two, one).value, false)
  @debug.assert_eq(f64_lt(context, neg_one, pos_zero).value, true)

  let quiet_nan = F64::from_bits(0x7FF8000000000000UL)
  let quiet_eq = f64_eq(context, quiet_nan, one)
  @debug.assert_eq(quiet_eq.value, false)
  assert_flags(quiet_eq.context, 0U)
  let signaling_eq = f64_eq_signaling(context, quiet_nan, one)
  @debug.assert_eq(signaling_eq.value, false)
  assert_flags(signaling_eq.context, ExceptionFlags::invalid().to_bits())
  let signaling_nan = F64::from_bits(0x7FF0000000000001UL)
  let quiet_le = f64_le_quiet(context, signaling_nan, one)
  @debug.assert_eq(quiet_le.value, false)
  assert_flags(quiet_le.context, ExceptionFlags::invalid().to_bits())
  let le_nan = f64_le(context, quiet_nan, one)
  @debug.assert_eq(le_nan.value, false)
  assert_flags(le_nan.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f64_add and f64_sub cover exact sums epsilon and specials" {
  let context = Context::default()
  let one = F64::from_bits(0x3FF0000000000000UL)
  let two = f64_add(context, one, one)
  @debug.assert_eq(two.value.to_bits(), 0x4000000000000000UL)
  assert_flags(two.context, 0U)

  let tiny = F64::from_bits(0x0000000000000001UL)
  let near = f64_add(context, one, tiny)
  @debug.assert_eq(near.value.to_bits(), 0x3FF0000000000000UL)
  assert_flags(near.context, ExceptionFlags::inexact().to_bits())
  let up = f64_add(context.with_rounding(Max), one, tiny)
  @debug.assert_eq(up.value.to_bits(), 0x3FF0000000000001UL)
  assert_flags(up.context, ExceptionFlags::inexact().to_bits())

  let invalid = f64_add(
    context,
    F64::from_bits(0x7FF0000000000000UL),
    F64::from_bits(0xFFF0000000000000UL),
  )
  @debug.assert_eq(invalid.value.to_bits(), 0xFFF8000000000000UL)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())
  let zero = f64_sub(context, one, one)
  @debug.assert_eq(zero.value.to_bits(), 0x0000000000000000UL)
  let min_zero = f64_sub(context.with_rounding(Min), one, one)
  @debug.assert_eq(min_zero.value.to_bits(), 0x8000000000000000UL)
  let two_minus_one = F64::from_bits(0x4000000000000000UL).sub(context, one)
  @debug.assert_eq(two_minus_one.value.to_bits(), 0x3FF0000000000000UL)
}

///|
test "f64_mul covers finite signs subnormals and special cases" {
  let context = Context::default()
  let one = F64::from_bits(0x3FF0000000000000UL)
  let two = F64::from_bits(0x4000000000000000UL)
  let product = one.mul(context, two)
  @debug.assert_eq(product.value.to_bits(), 0x4000000000000000UL)
  assert_flags(product.context, 0U)

  let neg = f64_mul(context, F64::from_bits(0xBFF0000000000000UL), two)
  @debug.assert_eq(neg.value.to_bits(), 0xC000000000000000UL)
  let quarter = f64_mul(
    context,
    F64::from_bits(0x3FE0000000000000UL),
    F64::from_bits(0x3FE0000000000000UL),
  )
  @debug.assert_eq(quarter.value.to_bits(), 0x3FD0000000000000UL)
  let tiny_times_two = f64_mul(
    context,
    F64::from_bits(0x0000000000000001UL),
    two,
  )
  @debug.assert_eq(tiny_times_two.value.to_bits(), 0x0000000000000002UL)
  assert_flags(tiny_times_two.context, 0U)

  let invalid = f64_mul(
    context,
    F64::from_bits(0x0000000000000000UL),
    F64::from_bits(0x7FF0000000000000UL),
  )
  @debug.assert_eq(invalid.value.to_bits(), 0xFFF8000000000000UL)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())
  let inf = f64_mul(
    context,
    F64::from_bits(0xFFF0000000000000UL),
    F64::from_bits(0x4000000000000000UL),
  )
  @debug.assert_eq(inf.value.to_bits(), 0xFFF0000000000000UL)
  let nan = f64_mul(context, F64::from_bits(0x7FF0000000000001UL), one)
  @debug.assert_eq(nan.value.to_bits(), 0x7FF8000000000001UL)
  assert_flags(nan.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f64_div covers exact quotient inexact and exceptional cases" {
  let context = Context::default()
  let one = F64::from_bits(0x3FF0000000000000UL)
  let two = F64::from_bits(0x4000000000000000UL)
  let half = f64_div(context, one, two)
  @debug.assert_eq(half.value.to_bits(), 0x3FE0000000000000UL)
  assert_flags(half.context, 0U)
  let neg_half = F64::from_bits(0xBFF0000000000000UL).div(context, two)
  @debug.assert_eq(neg_half.value.to_bits(), 0xBFE0000000000000UL)
  let third = f64_div(context, one, F64::from_bits(0x4008000000000000UL))
  @debug.assert_eq(third.value.to_bits(), 0x3FD5555555555555UL)
  assert_flags(third.context, ExceptionFlags::inexact().to_bits())

  let inf = f64_div(context, one, F64::from_bits(0x0000000000000000UL))
  @debug.assert_eq(inf.value.to_bits(), 0x7FF0000000000000UL)
  assert_flags(inf.context, ExceptionFlags::infinite().to_bits())
  let invalid = f64_div(
    context,
    F64::from_bits(0x0000000000000000UL),
    F64::from_bits(0x0000000000000000UL),
  )
  @debug.assert_eq(invalid.value.to_bits(), 0xFFF8000000000000UL)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())
  let finite_over_inf = f64_div(
    context,
    one,
    F64::from_bits(0x7FF0000000000000UL),
  )
  @debug.assert_eq(finite_over_inf.value.to_bits(), 0x0000000000000000UL)
  let nan = f64_div(context, F64::from_bits(0x7FF0000000000001UL), one)
  @debug.assert_eq(nan.value.to_bits(), 0x7FF8000000000001UL)
  assert_flags(nan.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f64_sqrt covers exact roots inexact and invalid negatives" {
  let context = Context::default()
  let four = F64::from_bits(0x4010000000000000UL)
  let two = f64_sqrt(context, four)
  @debug.assert_eq(two.value.to_bits(), 0x4000000000000000UL)
  assert_flags(two.context, 0U)
  let half = F64::from_bits(0x3FD0000000000000UL).sqrt(context)
  @debug.assert_eq(half.value.to_bits(), 0x3FE0000000000000UL)
  assert_flags(half.context, 0U)

  let sqrt_two = f64_sqrt(context, F64::from_bits(0x4000000000000000UL))
  @debug.assert_eq(sqrt_two.value.to_bits(), 0x3FF6A09E667F3BCDUL)
  assert_flags(sqrt_two.context, ExceptionFlags::inexact().to_bits())
  let neg_zero = f64_sqrt(context, F64::from_bits(0x8000000000000000UL))
  @debug.assert_eq(neg_zero.value.to_bits(), 0x8000000000000000UL)
  let invalid = f64_sqrt(context, F64::from_bits(0xBFF0000000000000UL))
  @debug.assert_eq(invalid.value.to_bits(), 0xFFF8000000000000UL)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())
  let inf = f64_sqrt(context, F64::from_bits(0x7FF0000000000000UL))
  @debug.assert_eq(inf.value.to_bits(), 0x7FF0000000000000UL)
  let nan = f64_sqrt(context, F64::from_bits(0x7FF0000000000001UL))
  @debug.assert_eq(nan.value.to_bits(), 0x7FF8000000000001UL)
  assert_flags(nan.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f64_rem follows IEEE nearest-even remainder and specials" {
  let context = Context::default()
  let five = F64::from_bits(0x4014000000000000UL)
  let two = F64::from_bits(0x4000000000000000UL)
  let rem = f64_rem(context, five, two)
  @debug.assert_eq(rem.value.to_bits(), 0x3FF0000000000000UL)
  assert_flags(rem.context, 0U)

  let seven = F64::from_bits(0x401C000000000000UL)
  let tie = seven.rem(context, two)
  @debug.assert_eq(tie.value.to_bits(), 0xBFF0000000000000UL)
  let small = f64_rem(
    context,
    F64::from_bits(0x3FF0000000000000UL),
    F64::from_bits(0x4010000000000000UL),
  )
  @debug.assert_eq(small.value.to_bits(), 0x3FF0000000000000UL)

  let by_inf = f64_rem(
    context,
    F64::from_bits(0xBFF0000000000000UL),
    F64::from_bits(0x7FF0000000000000UL),
  )
  @debug.assert_eq(by_inf.value.to_bits(), 0xBFF0000000000000UL)
  let invalid = f64_rem(context, F64::from_bits(0x7FF0000000000000UL), two)
  @debug.assert_eq(invalid.value.to_bits(), 0xFFF8000000000000UL)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())
  let zero_divisor = f64_rem(
    context,
    F64::from_bits(0x3FF0000000000000UL),
    F64::from_bits(0x0000000000000000UL),
  )
  @debug.assert_eq(zero_divisor.value.to_bits(), 0xFFF8000000000000UL)
  assert_flags(zero_divisor.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f64_mul_add fuses finite arithmetic and handles special products" {
  let context = Context::default()
  let one = F64::from_bits(0x3FF0000000000000UL)
  let two = F64::from_bits(0x4000000000000000UL)
  let three = F64::from_bits(0x4008000000000000UL)
  let fused = f64_mul_add(context, two, three, one)
  @debug.assert_eq(fused.value.to_bits(), 0x401C000000000000UL)
  assert_flags(fused.context, 0U)

  let cancel = f64_mul_add(
    context,
    one,
    one,
    F64::from_bits(0xBFF0000000000000UL),
  )
  @debug.assert_eq(cancel.value.to_bits(), 0x0000000000000000UL)
  let min_cancel = f64_mul_add(
    context.with_rounding(Min),
    one,
    one,
    F64::from_bits(0xBFF0000000000000UL),
  )
  @debug.assert_eq(min_cancel.value.to_bits(), 0x8000000000000000UL)

  let tiny = F64::from_bits(0x0000000000000001UL)
  let near = one.mul_add(context, one, tiny)
  @debug.assert_eq(near.value.to_bits(), 0x3FF0000000000000UL)
  assert_flags(near.context, ExceptionFlags::inexact().to_bits())
  let up = f64_mul_add(context.with_rounding(Max), one, one, tiny)
  @debug.assert_eq(up.value.to_bits(), 0x3FF0000000000001UL)
  assert_flags(up.context, ExceptionFlags::inexact().to_bits())

  let invalid_prod = f64_mul_add(
    context,
    F64::from_bits(0x7FF0000000000000UL),
    F64::from_bits(0x0000000000000000UL),
    one,
  )
  @debug.assert_eq(invalid_prod.value.to_bits(), 0xFFF8000000000000UL)
  assert_flags(invalid_prod.context, ExceptionFlags::invalid().to_bits())
  let invalid_sum = f64_mul_add(
    context,
    F64::from_bits(0x7FF0000000000000UL),
    one,
    F64::from_bits(0xFFF0000000000000UL),
  )
  @debug.assert_eq(invalid_sum.value.to_bits(), 0xFFF8000000000000UL)
  assert_flags(invalid_sum.context, ExceptionFlags::invalid().to_bits())
}
