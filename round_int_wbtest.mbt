///|
fn assert_flags(value : Context, bits : UInt) -> Unit raise {
  @debug.assert_eq(value.flags.to_bits(), bits)
}

///|
test "round_to_ui32 covers rounding modes and inexact flag" {
  let context = Context::default()
  let base = 2UL << 12
  let half = base | 0x800UL
  @debug.assert_eq(
    round_to_ui32(context, false, half, NearEven, true).value,
    2U,
  )
  @debug.assert_eq(
    round_to_ui32(context, false, half, NearMaxMag, true).value,
    3U,
  )
  @debug.assert_eq(round_to_ui32(context, false, half, MinMag, true).value, 2U)
  @debug.assert_eq(round_to_ui32(context, false, half, Min, true).value, 2U)
  @debug.assert_eq(round_to_ui32(context, false, half, Max, true).value, 3U)
  @debug.assert_eq(round_to_ui32(context, false, half, Odd, true).value, 3U)
  assert_flags(
    round_to_ui32(context, false, half, MinMag, true).context,
    ExceptionFlags::inexact().to_bits(),
  )
  assert_flags(round_to_ui32(context, false, half, MinMag, false).context, 0U)
}

///|
test "round_to_ui32 handles negative and overflow invalid results" {
  let x86 = Context::default()
  let riscv = Context::riscv()
  let tiny = 0x001UL
  let neg_tiny = round_to_ui32(x86, true, tiny, MinMag, true)
  @debug.assert_eq(neg_tiny.value, 0U)
  assert_flags(neg_tiny.context, ExceptionFlags::inexact().to_bits())
  let neg_min = round_to_ui32(riscv, true, tiny, Min, true)
  @debug.assert_eq(neg_min.value, 0U)
  assert_flags(neg_min.context, ExceptionFlags::invalid().to_bits())
  let neg_odd = round_to_ui32(x86, true, tiny, Odd, true)
  @debug.assert_eq(neg_odd.value, 0xFFFFFFFFU)
  assert_flags(neg_odd.context, ExceptionFlags::invalid().to_bits())
  let overflow = round_to_ui32(x86, false, 0xFFFFF00000000000UL, NearEven, true)
  @debug.assert_eq(overflow.value, 0xFFFFFFFFU)
  assert_flags(overflow.context, ExceptionFlags::invalid().to_bits())
}

///|
test "round_to_ui64 covers tie, odd, negative, and overflow" {
  let context = Context::default()
  let half = 0x8000000000000000UL
  @debug.assert_eq(
    round_to_ui64(context, false, 2UL, half, NearEven, true).value,
    2UL,
  )
  @debug.assert_eq(
    round_to_ui64(context, false, 2UL, half, NearMaxMag, true).value,
    3UL,
  )
  @debug.assert_eq(
    round_to_ui64(context, false, 2UL, 1UL, Odd, true).value,
    3UL,
  )
  assert_flags(
    round_to_ui64(context, false, 2UL, 1UL, Odd, true).context,
    ExceptionFlags::inexact().to_bits(),
  )
  let neg_tiny = round_to_ui64(Context::riscv(), true, 0UL, 1UL, MinMag, true)
  @debug.assert_eq(neg_tiny.value, 0UL)
  assert_flags(neg_tiny.context, ExceptionFlags::inexact().to_bits())
  let neg_min = round_to_ui64(Context::riscv(), true, 0UL, 1UL, Min, true)
  @debug.assert_eq(neg_min.value, 0UL)
  assert_flags(neg_min.context, ExceptionFlags::invalid().to_bits())
  let overflow = round_to_ui64(
    context,
    false,
    0xFFFFFFFFFFFFFFFFUL,
    1UL,
    Max,
    true,
  )
  @debug.assert_eq(overflow.value, 0xFFFFFFFFFFFFFFFFUL)
  assert_flags(overflow.context, ExceptionFlags::invalid().to_bits())
}

///|
test "round_to_i32 covers signed rounding and invalid boundaries" {
  let context = Context::default()
  let half = (2UL << 12) | 0x800UL
  @debug.assert_eq(round_to_i32(context, false, half, NearEven, true).value, 2)
  @debug.assert_eq(
    round_to_i32(context, false, half, NearMaxMag, true).value,
    3,
  )
  @debug.assert_eq(round_to_i32(context, true, half, Min, true).value, -3)
  @debug.assert_eq(round_to_i32(context, true, half, Max, true).value, -2)
  @debug.assert_eq(round_to_i32(context, true, half, Odd, true).value, -3)
  assert_flags(
    round_to_i32(context, true, half, Odd, true).context,
    ExceptionFlags::inexact().to_bits(),
  )
  let pos_overflow = round_to_i32(
    Context::riscv(),
    false,
    0x80000000UL << 12,
    MinMag,
    true,
  )
  @debug.assert_eq(pos_overflow.value, 0x7FFFFFFF)
  assert_flags(pos_overflow.context, ExceptionFlags::invalid().to_bits())
  let neg_min = round_to_i32(context, true, 0x80000000UL << 12, NearEven, true)
  @debug.assert_eq(neg_min.value, -0x7FFFFFFF - 1)
  assert_flags(neg_min.context, 0U)
}

///|
test "round_to_i64 covers signed tie, odd, and overflow" {
  let context = Context::default()
  let half = 0x8000000000000000UL
  @debug.assert_eq(
    round_to_i64(context, false, 2UL, half, NearEven, true).value,
    2L,
  )
  @debug.assert_eq(
    round_to_i64(context, false, 2UL, half, NearMaxMag, true).value,
    3L,
  )
  @debug.assert_eq(round_to_i64(context, true, 2UL, 1UL, Min, true).value, -3L)
  @debug.assert_eq(round_to_i64(context, true, 2UL, 1UL, Max, true).value, -2L)
  @debug.assert_eq(round_to_i64(context, true, 2UL, 1UL, Odd, true).value, -3L)
  assert_flags(
    round_to_i64(context, true, 2UL, 1UL, Odd, true).context,
    ExceptionFlags::inexact().to_bits(),
  )
  let pos_overflow = round_to_i64(
    Context::riscv(),
    false,
    0x8000000000000000UL,
    0UL,
    NearEven,
    true,
  )
  @debug.assert_eq(pos_overflow.value, 0x7FFFFFFFFFFFFFFFL)
  assert_flags(pos_overflow.context, ExceptionFlags::invalid().to_bits())
  let neg_min = round_to_i64(
    context,
    true,
    0x8000000000000000UL,
    0UL,
    NearEven,
    true,
  )
  @debug.assert_eq(neg_min.value, -0x7FFFFFFFFFFFFFFFL - 1L)
  assert_flags(neg_min.context, 0U)
}
