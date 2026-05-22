///|
fn assert_u128_eq(actual : UInt128, expected : UInt128) -> Unit raise {
  @debug.assert_eq(actual.hi, expected.hi)
  @debug.assert_eq(actual.lo, expected.lo)
}

///|
test "leading zero helpers match softfloat boundaries" {
  @debug.assert_eq(count_leading_zeros8(0U), 8)
  @debug.assert_eq(count_leading_zeros8(1U), 7)
  @debug.assert_eq(count_leading_zeros8(0x7FU), 1)
  @debug.assert_eq(count_leading_zeros8(0x80U), 0)
  @debug.assert_eq(count_leading_zeros16(0), 16)
  @debug.assert_eq(count_leading_zeros16(1), 15)
  @debug.assert_eq(count_leading_zeros16(0x00FF), 8)
  @debug.assert_eq(count_leading_zeros16(0x8000), 0)
  @debug.assert_eq(count_leading_zeros32(0U), 32)
  @debug.assert_eq(count_leading_zeros32(1U), 31)
  @debug.assert_eq(count_leading_zeros32(0x00FFFFFFU), 8)
  @debug.assert_eq(count_leading_zeros32(0x80000000U), 0)
  @debug.assert_eq(count_leading_zeros64(0UL), 64)
  @debug.assert_eq(count_leading_zeros64(1UL), 63)
  @debug.assert_eq(count_leading_zeros64(0x00000000FFFFFFFFUL), 32)
  @debug.assert_eq(count_leading_zeros64(0x8000000000000000UL), 0)
}

///|
test "jam shifts cover boundary distances" {
  @debug.assert_eq(shift_right_jam32(0x80000001U, 0), 0x80000001U)
  @debug.assert_eq(shift_right_jam32(0x80000001U, 1), 0x40000001U)
  @debug.assert_eq(shift_right_jam32(0x80000000U, 31), 1U)
  @debug.assert_eq(shift_right_jam32(0x80000000U, 32), 1U)
  @debug.assert_eq(shift_right_jam32(0x80000000U, 33), 1U)
  @debug.assert_eq(shift_right_jam32(0U, 33), 0U)

  @debug.assert_eq(
    shift_right_jam64(0x8000000000000001UL, 0),
    0x8000000000000001UL,
  )
  @debug.assert_eq(
    shift_right_jam64(0x8000000000000001UL, 1),
    0x4000000000000001UL,
  )
  @debug.assert_eq(shift_right_jam64(0x8000000000000000UL, 63), 1UL)
  @debug.assert_eq(shift_right_jam64(0x8000000000000000UL, 64), 1UL)
  @debug.assert_eq(shift_right_jam64(0x8000000000000000UL, 65), 1UL)
  @debug.assert_eq(short_shift_right_jam64(0x0000000000000001UL, 1), 1UL)

  let a = { hi: 1UL, lo: 0UL }
  assert_u128_eq(shift_right_jam128(a, 0), a)
  assert_u128_eq(shift_right_jam128(a, 1), { hi: 0UL, lo: 0x8000000000000000UL })
  assert_u128_eq(shift_right_jam128(a, 63), { hi: 0UL, lo: 2UL })
  assert_u128_eq(shift_right_jam128(a, 64), { hi: 0UL, lo: 1UL })
  assert_u128_eq(shift_right_jam128(a, 65), { hi: 0UL, lo: 1UL })
  assert_u128_eq(shift_right_jam128(a, 129), { hi: 0UL, lo: 1UL })
  assert_u128_eq(shift_right_jam128(uint128_zero(), 129), uint128_zero())

  let extra = shift_right_jam64_extra(1UL, 0UL, 1)
  @debug.assert_eq(extra.value, 0UL)
  @debug.assert_eq(extra.extra, 0x8000000000000000UL)
  let extra_jammed = shift_right_jam64_extra(0UL, 5UL, 65)
  @debug.assert_eq(extra_jammed.value, 0UL)
  @debug.assert_eq(extra_jammed.extra, 1UL)
}

///|
test "uint128 compare add sub shift and negation helpers" {
  let zero = uint128_zero()
  let one = { hi: 0UL, lo: 1UL }
  let high = { hi: 1UL, lo: 0UL }

  let carry = add128({ hi: 2UL, lo: 0xFFFFFFFFFFFFFFFFUL }, one)
  assert_u128_eq(carry, { hi: 3UL, lo: 0UL })
  assert_u128_eq(sub128(carry, one), { hi: 2UL, lo: 0xFFFFFFFFFFFFFFFFUL })
  assert_u128_eq(neg128(one), {
    hi: 0xFFFFFFFFFFFFFFFFUL,
    lo: 0xFFFFFFFFFFFFFFFFUL,
  })

  assert_u128_eq(short_shift_left128(one, 63), {
    hi: 0UL,
    lo: 0x8000000000000000UL,
  })
  assert_u128_eq(shift_left128_m(one, 64), high)
  assert_u128_eq(shift_left128_m(one, 65), { hi: 2UL, lo: 0UL })
  assert_u128_eq(shift_left128_m(one, 129), zero)
}

///|
test "mul64_to_128 covers carry boundaries" {
  assert_u128_eq(mul64_to_128(0UL, 0xFFFFFFFFFFFFFFFFUL), uint128_zero())
  assert_u128_eq(mul64_to_128(0xFFFFFFFFUL, 0xFFFFFFFFUL), {
    hi: 0UL,
    lo: 0xFFFFFFFE00000001UL,
  })
  assert_u128_eq(mul64_to_128(0xFFFFFFFFFFFFFFFFUL, 0xFFFFFFFFFFFFFFFFUL), {
    hi: 0xFFFFFFFFFFFFFFFEUL,
    lo: 1UL,
  })
}

///|
test "reciprocal approximation tables match c constants" {
  @debug.assert_eq(approx_recip_1k0(0), 0xFFC4UL)
  @debug.assert_eq(approx_recip_1k0(15), 0x8417UL)
  @debug.assert_eq(approx_recip_1k1(0), 0xF0F1UL)
  @debug.assert_eq(approx_recip_1k1(15), 0x4211UL)
  @debug.assert_eq(approx_recip_sqrt_1k0(0), 0xB4C9UL)
  @debug.assert_eq(approx_recip_sqrt_1k0(15), 0xBAE1UL)
  @debug.assert_eq(approx_recip_sqrt_1k1(0), 0xA5A5UL)
  @debug.assert_eq(approx_recip_sqrt_1k1(15), 0x5EFDUL)

  let recip = approx_recip32_1(0x80000000U)
  @debug.assert_eq(recip >= 0xFFFFFFF0U, true)
  let recip_sqrt_even = approx_recip_sqrt32_1(false, 0x80000000U)
  let recip_sqrt_odd = approx_recip_sqrt32_1(true, 0x80000000U)
  @debug.assert_eq((recip_sqrt_even & 0x80000000U) != 0U, true)
  @debug.assert_eq((recip_sqrt_odd & 0x80000000U) != 0U, true)
}
