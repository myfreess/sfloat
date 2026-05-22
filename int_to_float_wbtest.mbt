///|
test "integer to f16 conversions round and flag like softfloat" {
  let context = Context::default()
  let one = ui32_to_f16(context, 1U)
  @debug.assert_eq(one.value.to_bits(), 0x3C00)
  assert_flags(one.context, 0U)
  let neg_two = i32_to_f16(context, -2)
  @debug.assert_eq(neg_two.value.to_bits(), 0xC000)
  assert_flags(neg_two.context, 0U)
  let max_finite = ui32_to_f16(context, 65504U)
  @debug.assert_eq(max_finite.value.to_bits(), 0x7BFF)
  assert_flags(max_finite.context, 0U)

  let overflow = ui64_to_f16(context, 0xFFFFFFFFFFFFFFFFUL)
  @debug.assert_eq(overflow.value.to_bits(), 0x7C00)
  assert_flags(
    overflow.context,
    ExceptionFlags::overflow().merge(ExceptionFlags::inexact()).to_bits(),
  )
  let neg_overflow = i64_to_f16(context, -0x7FFFFFFFFFFFFFFFL - 1L)
  @debug.assert_eq(neg_overflow.value.to_bits(), 0xFC00)
  assert_flags(
    neg_overflow.context,
    ExceptionFlags::overflow().merge(ExceptionFlags::inexact()).to_bits(),
  )
}

///|
test "integer to f32 conversions cover exact and rounded boundaries" {
  let context = Context::default()
  let high_bit = ui32_to_f32(context, 0x80000000U)
  @debug.assert_eq(high_bit.value.to_bits(), 0x4F000000U)
  assert_flags(high_bit.context, 0U)
  let all_bits = ui32_to_f32(context, 0xFFFFFFFFU)
  @debug.assert_eq(all_bits.value.to_bits(), 0x4F800000U)
  assert_flags(all_bits.context, ExceptionFlags::inexact().to_bits())

  let min_i32 = i32_to_f32(context, -0x7FFFFFFF - 1)
  @debug.assert_eq(min_i32.value.to_bits(), 0xCF000000U)
  assert_flags(min_i32.context, 0U)
  let max_u64 = ui64_to_f32(context, 0xFFFFFFFFFFFFFFFFUL)
  @debug.assert_eq(max_u64.value.to_bits(), 0x5F800000U)
  assert_flags(max_u64.context, ExceptionFlags::inexact().to_bits())
  let min_i64 = i64_to_f32(context, -0x7FFFFFFFFFFFFFFFL - 1L)
  @debug.assert_eq(min_i64.value.to_bits(), 0xDF000000U)
  assert_flags(min_i64.context, 0U)
}

///|
test "integer to f64 conversions preserve exact values until precision limit" {
  let context = Context::default()
  let one = ui32_to_f64(context, 1U)
  @debug.assert_eq(one.value.to_bits(), 0x3FF0000000000000UL)
  assert_flags(one.context, 0U)
  let neg_two = i32_to_f64(context, -2)
  @debug.assert_eq(neg_two.value.to_bits(), 0xC000000000000000UL)
  assert_flags(neg_two.context, 0U)
  let min_i64 = i64_to_f64(context, -0x7FFFFFFFFFFFFFFFL - 1L)
  @debug.assert_eq(min_i64.value.to_bits(), 0xC3E0000000000000UL)
  assert_flags(min_i64.context, 0U)
  let max_u64 = ui64_to_f64(context, 0xFFFFFFFFFFFFFFFFUL)
  @debug.assert_eq(max_u64.value.to_bits(), 0x43F0000000000000UL)
  assert_flags(max_u64.context, ExceptionFlags::inexact().to_bits())
}
