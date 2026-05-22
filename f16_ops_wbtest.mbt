///|
test "f16_to_f32 and f16_to_f64 convert finite values exactly" {
  let context = Context::default()
  let one32 = F16::from_bits(0x3C00).to_f32(context)
  @debug.assert_eq(one32.value.to_bits(), 0x3F800000U)
  assert_flags(one32.context, 0U)
  let one64 = f16_to_f64(context, F16::from_bits(0x3C00))
  @debug.assert_eq(one64.value.to_bits(), 0x3FF0000000000000UL)
  assert_flags(one64.context, 0U)

  let neg_zero32 = f16_to_f32(context, F16::from_bits(0x8000))
  @debug.assert_eq(neg_zero32.value.to_bits(), 0x80000000U)
  let sub32 = F16::from_bits(0x0001).to_f32(context)
  @debug.assert_eq(sub32.value.to_bits(), 0x33800000U)
  let sub64 = F16::from_bits(0x0001).to_f64(context)
  @debug.assert_eq(sub64.value.to_bits(), 0x3E70000000000000UL)
}

///|
test "f16_to_f32 and f16_to_f64 handle infinities and nan specialization" {
  let context = Context::default()
  let inf32 = F16::from_bits(0x7C00).to_f32(context)
  @debug.assert_eq(inf32.value.to_bits(), 0x7F800000U)
  assert_flags(inf32.context, 0U)
  let inf64 = F16::from_bits(0xFC00).to_f64(context)
  @debug.assert_eq(inf64.value.to_bits(), 0xFFF0000000000000UL)
  assert_flags(inf64.context, 0U)

  let x86 = F16::from_bits(0x7C01).to_f32(context)
  @debug.assert_eq(x86.value.to_bits(), 0x7FC02000U)
  assert_flags(x86.context, ExceptionFlags::invalid().to_bits())
  let riscv = F16::from_bits(0x7C01).to_f64(Context::riscv())
  @debug.assert_eq(riscv.value.to_bits(), 0x7FF8000000000000UL)
  assert_flags(riscv.context, ExceptionFlags::invalid().to_bits())
  @debug.assert_eq(f16_is_signaling_nan(F16::from_bits(0x7C01)), true)
}

///|
test "f16 integer conversions honor rounding and exact flags" {
  let context = Context::default()
  let one = F16::from_bits(0x3C00)
  @debug.assert_eq(one.to_ui32(context, NearEven, true).value, 1U)
  @debug.assert_eq(f16_to_ui64(context, one, NearEven, true).value, 1UL)
  @debug.assert_eq(one.to_i32(context, NearEven, true).value, 1)
  @debug.assert_eq(f16_to_i64(context, one, NearEven, true).value, 1L)

  let one_half = F16::from_bits(0x3E00)
  let near = one_half.to_ui32(context, NearEven, true)
  @debug.assert_eq(near.value, 2U)
  assert_flags(near.context, ExceptionFlags::inexact().to_bits())
  @debug.assert_eq(one_half.to_ui32(context, MinMag, true).value, 1U)
  @debug.assert_eq(one_half.to_ui32(context, Max, true).value, 2U)
  @debug.assert_eq(one_half.to_ui32(context, Odd, true).value, 1U)

  let neg = F16::from_bits(0xBE00)
  @debug.assert_eq(neg.to_i32(context, Min, true).value, -2)
  @debug.assert_eq(neg.to_i32(context, Max, true).value, -1)
  @debug.assert_eq(neg.to_i64(context, Odd, true).value, -1L)
}

///|
test "f16 integer conversions return specialization invalid constants" {
  let x86 = Context::default()
  let riscv = Context::riscv()
  let neg_one = F16::from_bits(0xBC00)
  let x86_unsigned = neg_one.to_ui32(x86, NearEven, true)
  @debug.assert_eq(x86_unsigned.value, 0xFFFFFFFFU)
  assert_flags(x86_unsigned.context, ExceptionFlags::invalid().to_bits())
  let riscv_unsigned = neg_one.to_ui32(riscv, NearEven, true)
  @debug.assert_eq(riscv_unsigned.value, 0U)
  assert_flags(riscv_unsigned.context, ExceptionFlags::invalid().to_bits())

  let nan_i64 = F16::from_bits(0x7E00).to_i64(x86, NearEven, true)
  @debug.assert_eq(nan_i64.value, -0x7FFFFFFFFFFFFFFFL - 1L)
  assert_flags(nan_i64.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f16 minMag integer conversions truncate and flag inexact" {
  let context = Context::default()
  let one_half = F16::from_bits(0x3E00)
  let ui32 = f16_to_ui32_min_mag(context, one_half, true)
  @debug.assert_eq(ui32.value, 1U)
  assert_flags(ui32.context, ExceptionFlags::inexact().to_bits())
  @debug.assert_eq(f16_to_ui64_min_mag(context, one_half, true).value, 1UL)

  let neg = F16::from_bits(0xBE00)
  let i32 = f16_to_i32_min_mag(context, neg, true)
  @debug.assert_eq(i32.value, -1)
  assert_flags(i32.context, ExceptionFlags::inexact().to_bits())
  @debug.assert_eq(f16_to_i64_min_mag(context, neg, true).value, -1L)

  let neg_ui = f16_to_ui32_min_mag(
    Context::riscv(),
    F16::from_bits(0xBC00),
    true,
  )
  @debug.assert_eq(neg_ui.value, 0U)
  assert_flags(neg_ui.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f16_round_to_int handles tiny values and directed modes" {
  let context = Context::default()
  let half = F16::from_bits(0x3800)
  let near_even = f16_round_to_int(context, half, NearEven, true)
  @debug.assert_eq(near_even.value.to_bits(), 0x0000)
  assert_flags(near_even.context, ExceptionFlags::inexact().to_bits())
  @debug.assert_eq(
    f16_round_to_int(context, half, NearMaxMag, true).value.to_bits(),
    0x3C00,
  )
  @debug.assert_eq(
    f16_round_to_int(context, half, Odd, true).value.to_bits(),
    0x3C00,
  )

  let neg_half = F16::from_bits(0xB800)
  @debug.assert_eq(
    f16_round_to_int(context, neg_half, Min, true).value.to_bits(),
    0xBC00,
  )
  @debug.assert_eq(
    f16_round_to_int(context, neg_half, Max, true).value.to_bits(),
    0x8000,
  )
}

///|
test "f16_round_to_int rounds middle exponents and honors exact" {
  let context = Context::default()
  let one_half = F16::from_bits(0x3E00)
  let near_even = one_half.round_to_int(context, NearEven, true)
  @debug.assert_eq(near_even.value.to_bits(), 0x4000)
  assert_flags(near_even.context, ExceptionFlags::inexact().to_bits())
  @debug.assert_eq(
    f16_round_to_int(context, one_half, MinMag, true).value.to_bits(),
    0x3C00,
  )
  @debug.assert_eq(
    f16_round_to_int(context, one_half, Max, true).value.to_bits(),
    0x4000,
  )

  let two_half = F16::from_bits(0x4100)
  @debug.assert_eq(
    f16_round_to_int(context, two_half, Odd, true).value.to_bits(),
    0x4200,
  )
  let quiet = f16_round_to_int(context, one_half, NearEven, false)
  @debug.assert_eq(quiet.value.to_bits(), 0x4000)
  assert_flags(quiet.context, 0U)
}

///|
test "f16_round_to_int returns integers unchanged and propagates nan" {
  let context = Context::default()
  let large_integer = f16_round_to_int(
    context,
    F16::from_bits(0x6400),
    NearEven,
    true,
  )
  @debug.assert_eq(large_integer.value.to_bits(), 0x6400)
  assert_flags(large_integer.context, 0U)

  let quiet_nan = f16_round_to_int(
    context,
    F16::from_bits(0x7E01),
    NearEven,
    true,
  )
  @debug.assert_eq(quiet_nan.value.to_bits(), 0x7E01)
  assert_flags(quiet_nan.context, 0U)
  let signaling_nan = f16_round_to_int(
    context,
    F16::from_bits(0x7C01),
    NearEven,
    true,
  )
  @debug.assert_eq(signaling_nan.value.to_bits(), 0x7E01)
  assert_flags(signaling_nan.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f16_add covers exact sums subnormals and epsilon rounding" {
  let context = Context::default()
  let one = F16::from_bits(0x3C00)
  let two = f16_add(context, one, one)
  @debug.assert_eq(two.value.to_bits(), 0x4000)
  assert_flags(two.context, 0U)

  let tiny = F16::from_bits(0x0001)
  @debug.assert_eq(f16_add(context, tiny, tiny).value.to_bits(), 0x0002)
  let near = f16_add(context, one, tiny)
  @debug.assert_eq(near.value.to_bits(), 0x3C00)
  assert_flags(near.context, ExceptionFlags::inexact().to_bits())
  let up = f16_add(context.with_rounding(Max), one, tiny)
  @debug.assert_eq(up.value.to_bits(), 0x3C01)
  assert_flags(up.context, ExceptionFlags::inexact().to_bits())
}

///|
test "f16_add and f16_sub handle infinities cancellation and sub epsilon" {
  let context = Context::default()
  let invalid = f16_add(context, F16::from_bits(0x7C00), F16::from_bits(0xFC00))
  @debug.assert_eq(invalid.value.to_bits(), 0xFE00)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())

  let one = F16::from_bits(0x3C00)
  let zero = f16_sub(context, one, one)
  @debug.assert_eq(zero.value.to_bits(), 0x0000)
  assert_flags(zero.context, 0U)
  let min_zero = f16_sub(context.with_rounding(Min), one, one)
  @debug.assert_eq(min_zero.value.to_bits(), 0x8000)

  let two_minus_one = F16::from_bits(0x4000).sub(context, one)
  @debug.assert_eq(two_minus_one.value.to_bits(), 0x3C00)
  let tiny = F16::from_bits(0x0001)
  let near = f16_sub(context, one, tiny)
  @debug.assert_eq(near.value.to_bits(), 0x3C00)
  assert_flags(near.context, ExceptionFlags::inexact().to_bits())
  let min_mag = f16_sub(context.with_rounding(MinMag), one, tiny)
  @debug.assert_eq(min_mag.value.to_bits(), 0x3BFF)
  assert_flags(min_mag.context, ExceptionFlags::inexact().to_bits())
}

///|
test "f16_mul covers finite signs subnormals and special cases" {
  let context = Context::default()
  let one = F16::from_bits(0x3C00)
  let two = F16::from_bits(0x4000)
  let product = one.mul(context, two)
  @debug.assert_eq(product.value.to_bits(), 0x4000)
  assert_flags(product.context, 0U)

  let neg = f16_mul(context, F16::from_bits(0xBC00), two)
  @debug.assert_eq(neg.value.to_bits(), 0xC000)
  let quarter = f16_mul(context, F16::from_bits(0x3800), F16::from_bits(0x3800))
  @debug.assert_eq(quarter.value.to_bits(), 0x3400)
  let tiny_times_two = f16_mul(context, F16::from_bits(0x0001), two)
  @debug.assert_eq(tiny_times_two.value.to_bits(), 0x0002)
  assert_flags(tiny_times_two.context, 0U)

  let invalid = f16_mul(context, F16::from_bits(0x0000), F16::from_bits(0x7C00))
  @debug.assert_eq(invalid.value.to_bits(), 0xFE00)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())
  let inf = f16_mul(context, F16::from_bits(0xFC00), F16::from_bits(0x4000))
  @debug.assert_eq(inf.value.to_bits(), 0xFC00)
  let nan = f16_mul(context, F16::from_bits(0x7C01), one)
  @debug.assert_eq(nan.value.to_bits(), 0x7E01)
  assert_flags(nan.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f16_div covers exact quotient inexact and exceptional cases" {
  let context = Context::default()
  let one = F16::from_bits(0x3C00)
  let two = F16::from_bits(0x4000)
  let half = f16_div(context, one, two)
  @debug.assert_eq(half.value.to_bits(), 0x3800)
  assert_flags(half.context, 0U)
  let neg_half = F16::from_bits(0xBC00).div(context, two)
  @debug.assert_eq(neg_half.value.to_bits(), 0xB800)

  let third = f16_div(context, one, F16::from_bits(0x4200))
  @debug.assert_eq(third.value.to_bits(), 0x3555)
  assert_flags(third.context, ExceptionFlags::inexact().to_bits())
  let tiny = f16_div(context, F16::from_bits(0x0001), one)
  @debug.assert_eq(tiny.value.to_bits(), 0x0001)
  assert_flags(tiny.context, 0U)

  let inf = f16_div(context, one, F16::from_bits(0x0000))
  @debug.assert_eq(inf.value.to_bits(), 0x7C00)
  assert_flags(inf.context, ExceptionFlags::infinite().to_bits())
  let invalid = f16_div(context, F16::from_bits(0x0000), F16::from_bits(0x0000))
  @debug.assert_eq(invalid.value.to_bits(), 0xFE00)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())
  let finite_over_inf = f16_div(context, one, F16::from_bits(0x7C00))
  @debug.assert_eq(finite_over_inf.value.to_bits(), 0x0000)
  let nan = f16_div(context, F16::from_bits(0x7C01), one)
  @debug.assert_eq(nan.value.to_bits(), 0x7E01)
  assert_flags(nan.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f16_sqrt covers exact roots inexact and invalid negatives" {
  let context = Context::default()
  let four = F16::from_bits(0x4400)
  let two = f16_sqrt(context, four)
  @debug.assert_eq(two.value.to_bits(), 0x4000)
  assert_flags(two.context, 0U)
  let half = F16::from_bits(0x3400).sqrt(context)
  @debug.assert_eq(half.value.to_bits(), 0x3800)
  assert_flags(half.context, 0U)

  let sqrt_two = f16_sqrt(context, F16::from_bits(0x4000))
  @debug.assert_eq(sqrt_two.value.to_bits(), 0x3DA8)
  assert_flags(sqrt_two.context, ExceptionFlags::inexact().to_bits())
  let neg_zero = f16_sqrt(context, F16::from_bits(0x8000))
  @debug.assert_eq(neg_zero.value.to_bits(), 0x8000)
  let invalid = f16_sqrt(context, F16::from_bits(0xBC00))
  @debug.assert_eq(invalid.value.to_bits(), 0xFE00)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())
  let inf = f16_sqrt(context, F16::from_bits(0x7C00))
  @debug.assert_eq(inf.value.to_bits(), 0x7C00)
  let nan = f16_sqrt(context, F16::from_bits(0x7C01))
  @debug.assert_eq(nan.value.to_bits(), 0x7E01)
  assert_flags(nan.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f16_rem follows IEEE nearest-even remainder and specials" {
  let context = Context::default()
  let five = F16::from_bits(0x4500)
  let two = F16::from_bits(0x4000)
  let rem = f16_rem(context, five, two)
  @debug.assert_eq(rem.value.to_bits(), 0x3C00)
  assert_flags(rem.context, 0U)

  let seven = F16::from_bits(0x4700)
  let tie = seven.rem(context, two)
  @debug.assert_eq(tie.value.to_bits(), 0xBC00)
  let small = f16_rem(context, F16::from_bits(0x3C00), F16::from_bits(0x4400))
  @debug.assert_eq(small.value.to_bits(), 0x3C00)

  let by_inf = f16_rem(context, F16::from_bits(0xBC00), F16::from_bits(0x7C00))
  @debug.assert_eq(by_inf.value.to_bits(), 0xBC00)
  let invalid = f16_rem(context, F16::from_bits(0x7C00), two)
  @debug.assert_eq(invalid.value.to_bits(), 0xFE00)
  assert_flags(invalid.context, ExceptionFlags::invalid().to_bits())
  let zero_divisor = f16_rem(
    context,
    F16::from_bits(0x3C00),
    F16::from_bits(0x0000),
  )
  @debug.assert_eq(zero_divisor.value.to_bits(), 0xFE00)
  assert_flags(zero_divisor.context, ExceptionFlags::invalid().to_bits())
  let nan = f16_rem(context, F16::from_bits(0x7C01), two)
  @debug.assert_eq(nan.value.to_bits(), 0x7E01)
  assert_flags(nan.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f16_mul_add fuses finite arithmetic and cancellation sign" {
  let context = Context::default()
  let one = F16::from_bits(0x3C00)
  let two = F16::from_bits(0x4000)
  let three = F16::from_bits(0x4200)
  let fused = f16_mul_add(context, two, three, one)
  @debug.assert_eq(fused.value.to_bits(), 0x4700)
  assert_flags(fused.context, 0U)

  let cancel = f16_mul_add(context, one, one, F16::from_bits(0xBC00))
  @debug.assert_eq(cancel.value.to_bits(), 0x0000)
  let min_cancel = f16_mul_add(
    context.with_rounding(Min),
    one,
    one,
    F16::from_bits(0xBC00),
  )
  @debug.assert_eq(min_cancel.value.to_bits(), 0x8000)

  let tiny = F16::from_bits(0x0001)
  let near = one.mul_add(context, one, tiny)
  @debug.assert_eq(near.value.to_bits(), 0x3C00)
  assert_flags(near.context, ExceptionFlags::inexact().to_bits())
  let up = f16_mul_add(context.with_rounding(Max), one, one, tiny)
  @debug.assert_eq(up.value.to_bits(), 0x3C01)
  assert_flags(up.context, ExceptionFlags::inexact().to_bits())
}

///|
test "f16_mul_add handles product infinities and nan propagation" {
  let context = Context::default()
  let one = F16::from_bits(0x3C00)
  let invalid_prod = f16_mul_add(
    context,
    F16::from_bits(0x7C00),
    F16::from_bits(0x0000),
    one,
  )
  @debug.assert_eq(invalid_prod.value.to_bits(), 0xFE00)
  assert_flags(invalid_prod.context, ExceptionFlags::invalid().to_bits())
  let invalid_sum = f16_mul_add(
    context,
    F16::from_bits(0x7C00),
    one,
    F16::from_bits(0xFC00),
  )
  @debug.assert_eq(invalid_sum.value.to_bits(), 0xFE00)
  assert_flags(invalid_sum.context, ExceptionFlags::invalid().to_bits())
  let nan_c = f16_mul_add(context, one, one, F16::from_bits(0x7C01))
  @debug.assert_eq(nan_c.value.to_bits(), 0x7E01)
  assert_flags(nan_c.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f16 comparisons handle ordering signed zeros and nan invalid flags" {
  let context = Context::default()
  let neg_zero = F16::from_bits(0x8000)
  let pos_zero = F16::from_bits(0x0000)
  let one = F16::from_bits(0x3C00)
  let two = F16::from_bits(0x4000)
  let neg_one = F16::from_bits(0xBC00)

  @debug.assert_eq(f16_eq(context, neg_zero, pos_zero).value, true)
  @debug.assert_eq(f16_lt(context, one, two).value, true)
  @debug.assert_eq(f16_le(context, two, one).value, false)
  @debug.assert_eq(f16_lt(context, neg_one, pos_zero).value, true)
  @debug.assert_eq(f16_le_quiet(context, neg_zero, pos_zero).value, true)

  let qnan = F16::from_bits(0x7E00)
  let snan = F16::from_bits(0x7C01)
  let quiet_eq = f16_eq(context, qnan, one)
  @debug.assert_eq(quiet_eq.value, false)
  assert_flags(quiet_eq.context, 0U)
  let signaling_eq = f16_eq_signaling(context, qnan, one)
  @debug.assert_eq(signaling_eq.value, false)
  assert_flags(signaling_eq.context, ExceptionFlags::invalid().to_bits())
  let quiet_le_snan = f16_le_quiet(context, snan, one)
  @debug.assert_eq(quiet_le_snan.value, false)
  assert_flags(quiet_le_snan.context, ExceptionFlags::invalid().to_bits())
  let le_qnan = f16_le(context, qnan, one)
  @debug.assert_eq(le_qnan.value, false)
  assert_flags(le_qnan.context, ExceptionFlags::invalid().to_bits())
}
