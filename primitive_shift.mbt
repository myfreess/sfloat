///|
/// Ports `softfloat_countLeadingZeros8` from `s_countLeadingZeros8.c`.
fn count_leading_zeros8(a : UInt) -> Int {
  let a = a & 0xFFU
  if a >= 0x80U {
    0
  } else if a >= 0x40U {
    1
  } else if a >= 0x20U {
    2
  } else if a >= 0x10U {
    3
  } else if a >= 0x08U {
    4
  } else if a >= 0x04U {
    5
  } else if a >= 0x02U {
    6
  } else if a >= 0x01U {
    7
  } else {
    8
  }
}

///|
/// Ports `softfloat_countLeadingZeros16` from `s_countLeadingZeros16.c`.
fn count_leading_zeros16(a : UInt16) -> Int {
  if a >= 0x0100 {
    count_leading_zeros8((a >> 8).to_uint())
  } else {
    8 + count_leading_zeros8(a.to_uint())
  }
}

///|
/// Ports `softfloat_countLeadingZeros32` from `s_countLeadingZeros32.c`.
fn count_leading_zeros32(a : UInt) -> Int {
  if a >= 0x01000000U {
    count_leading_zeros8(a >> 24)
  } else if a >= 0x00010000U {
    8 + count_leading_zeros8(a >> 16)
  } else if a >= 0x00000100U {
    16 + count_leading_zeros8(a >> 8)
  } else {
    24 + count_leading_zeros8(a)
  }
}

///|
/// Ports `softfloat_countLeadingZeros64` from `s_countLeadingZeros64.c`.
fn count_leading_zeros64(a : UInt64) -> Int {
  let hi = (a >> 32).to_uint()
  if hi != 0U {
    count_leading_zeros32(hi)
  } else {
    32 + count_leading_zeros32(a.to_uint())
  }
}

///|
fn jam_bit64(nonzero : Bool) -> UInt64 {
  if nonzero {
    1UL
  } else {
    0UL
  }
}

///|
fn jam_bit32(nonzero : Bool) -> UInt {
  if nonzero {
    1U
  } else {
    0U
  }
}

///|
/// Ports `softfloat_shiftRightJam32` from `s_shiftRightJam32.c`.
fn shift_right_jam32(a : UInt, dist : Int) -> UInt {
  if dist <= 0 {
    a
  } else if dist < 32 {
    let mask = (1U << dist) - 1U
    (a >> dist) | jam_bit32((a & mask) != 0U)
  } else {
    jam_bit32(a != 0U)
  }
}

///|
/// Ports `softfloat_shortShiftRightJam64` from `s_shortShiftRightJam64.c`.
fn short_shift_right_jam64(a : UInt64, dist : Int) -> UInt64 {
  shift_right_jam64(a, dist)
}

///|
/// Ports `softfloat_shiftRightJam64` from `s_shiftRightJam64.c`.
fn shift_right_jam64(a : UInt64, dist : Int) -> UInt64 {
  if dist <= 0 {
    a
  } else if dist < 64 {
    let mask = (1UL << dist) - 1UL
    (a >> dist) | jam_bit64((a & mask) != 0UL)
  } else {
    jam_bit64(a != 0UL)
  }
}

///|
/// Ports `softfloat_shiftRightJam64Extra` from `s_shiftRightJam64Extra.c`.
fn shift_right_jam64_extra(
  a : UInt64,
  extra : UInt64,
  dist : Int,
) -> UInt64Extra {
  if dist <= 0 {
    { value: a, extra }
  } else {
    let shifted = if dist < 64 {
      { value: a >> dist, extra: a << (64 - dist) }
    } else {
      { value: 0UL, extra: if dist == 64 { a } else { jam_bit64(a != 0UL) } }
    }
    { ..shifted, extra: shifted.extra | jam_bit64(extra != 0UL) }
  }
}

///|
/// Ports `softfloat_shortShiftRightJam128` from `s_shortShiftRightJam128.c`.
fn short_shift_right_jam128(a : UInt128, dist : Int) -> UInt128 {
  if dist <= 0 {
    a
  } else if dist < 64 {
    let mask = (1UL << dist) - 1UL
    {
      hi: a.hi >> dist,
      lo: (a.hi << (64 - dist)) |
      (a.lo >> dist) |
      jam_bit64((a.lo & mask) != 0UL),
    }
  } else {
    shift_right_jam128(a, dist)
  }
}

///|
/// Ports `softfloat_shiftRightJam128` from `s_shiftRightJam128.c`.
fn shift_right_jam128(a : UInt128, dist : Int) -> UInt128 {
  if dist <= 0 {
    a
  } else if dist < 64 {
    short_shift_right_jam128(a, dist)
  } else if dist < 128 {
    let word_dist = dist - 64
    let shifted = if word_dist == 0 { a.hi } else { a.hi >> word_dist }
    let jammed = if word_dist == 0 {
      a.lo != 0UL
    } else {
      ((a.hi & ((1UL << word_dist) - 1UL)) | a.lo) != 0UL
    }
    { hi: 0UL, lo: shifted | jam_bit64(jammed) }
  } else {
    { hi: 0UL, lo: jam_bit64(!uint128_is_zero(a)) }
  }
}
