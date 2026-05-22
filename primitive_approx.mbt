///|
/// Table entry from `softfloat_approxRecip_1k0s` in `s_approxRecip_1Ks.c`.
fn approx_recip_1k0(index : Int) -> UInt64 {
  match index {
    0 => 0xFFC4UL
    1 => 0xF0BEUL
    2 => 0xE363UL
    3 => 0xD76FUL
    4 => 0xCCADUL
    5 => 0xC2F0UL
    6 => 0xBA16UL
    7 => 0xB201UL
    8 => 0xAA97UL
    9 => 0xA3C6UL
    10 => 0x9D7AUL
    11 => 0x97A6UL
    12 => 0x923CUL
    13 => 0x8D32UL
    14 => 0x887EUL
    15 => 0x8417UL
    _ => abort("approx_recip_1k0 index out of range")
  }
}

///|
/// Table entry from `softfloat_approxRecip_1k1s` in `s_approxRecip_1Ks.c`.
fn approx_recip_1k1(index : Int) -> UInt64 {
  match index {
    0 => 0xF0F1UL
    1 => 0xD62CUL
    2 => 0xBFA1UL
    3 => 0xAC77UL
    4 => 0x9C0AUL
    5 => 0x8DDBUL
    6 => 0x8185UL
    7 => 0x76BAUL
    8 => 0x6D3BUL
    9 => 0x64D4UL
    10 => 0x5D5CUL
    11 => 0x56B1UL
    12 => 0x50B6UL
    13 => 0x4B55UL
    14 => 0x4679UL
    15 => 0x4211UL
    _ => abort("approx_recip_1k1 index out of range")
  }
}

///|
/// Ports `softfloat_approxRecip32_1` from `s_approxRecip32_1.c`.
fn approx_recip32_1(a : UInt) -> UInt {
  let index = ((a >> 27) & 0xFU).reinterpret_as_int()
  let eps = ((a >> 11) & 0xFFFFU).to_uint64()
  let r0 = approx_recip_1k0(index) - ((approx_recip_1k1(index) * eps) >> 20)
  let sigma0 = 0xFFFFFFFFU - ((r0 * a.to_uint64()) >> 7).to_uint()
  let sigma0_64 = sigma0.to_uint64()
  let mut r = (r0 << 16) + ((r0 * sigma0_64) >> 24)
  let sqr_sigma0 = (sigma0_64 * sigma0_64) >> 32
  r = r + (((r & 0xFFFFFFFFUL) * sqr_sigma0) >> 48)
  r.to_uint()
}

///|
/// Table entry from `softfloat_approxRecipSqrt_1k0s` in
/// `s_approxRecipSqrt_1Ks.c`.
fn approx_recip_sqrt_1k0(index : Int) -> UInt64 {
  match index {
    0 => 0xB4C9UL
    1 => 0xFFABUL
    2 => 0xAA7DUL
    3 => 0xF11CUL
    4 => 0xA1C5UL
    5 => 0xE4C7UL
    6 => 0x9A43UL
    7 => 0xDA29UL
    8 => 0x93B5UL
    9 => 0xD0E5UL
    10 => 0x8DEDUL
    11 => 0xC8B7UL
    12 => 0x88C6UL
    13 => 0xC16DUL
    14 => 0x8424UL
    15 => 0xBAE1UL
    _ => abort("approx_recip_sqrt_1k0 index out of range")
  }
}

///|
/// Table entry from `softfloat_approxRecipSqrt_1k1s` in
/// `s_approxRecipSqrt_1Ks.c`.
fn approx_recip_sqrt_1k1(index : Int) -> UInt64 {
  match index {
    0 => 0xA5A5UL
    1 => 0xEA42UL
    2 => 0x8C21UL
    3 => 0xC62DUL
    4 => 0x788FUL
    5 => 0xAA7FUL
    6 => 0x6928UL
    7 => 0x94B6UL
    8 => 0x5CC7UL
    9 => 0x8335UL
    10 => 0x52A6UL
    11 => 0x74E2UL
    12 => 0x4A3EUL
    13 => 0x68FEUL
    14 => 0x432BUL
    15 => 0x5EFDUL
    _ => abort("approx_recip_sqrt_1k1 index out of range")
  }
}

///|
/// Ports `softfloat_approxRecipSqrt32_1` from
/// `s_approxRecipSqrt32_1.c`.
fn approx_recip_sqrt32_1(odd_exp_a : Bool, a : UInt) -> UInt {
  let index = ((a >> 27) & 0xEU).reinterpret_as_int() +
    (if odd_exp_a { 1 } else { 0 })
  let eps = ((a >> 12) & 0xFFFFU).to_uint64()
  let r0 = approx_recip_sqrt_1k0(index) -
    ((approx_recip_sqrt_1k1(index) * eps) >> 20)
  let e_sqr_r0 = if odd_exp_a { r0 * r0 } else { (r0 * r0) << 1 }
  let sigma0 = 0xFFFFFFFFU -
    (((e_sqr_r0 & 0xFFFFFFFFUL) * a.to_uint64()) >> 23).to_uint()
  let sigma0_64 = sigma0.to_uint64()
  let r = (r0 << 16) + ((r0 * sigma0_64) >> 25)
  let sqr_sigma0 = (sigma0_64 * sigma0_64) >> 32
  let correction = ((r >> 1) + (r >> 3) - (r0 << 14)) & 0xFFFFFFFFUL
  let r = r + ((correction * sqr_sigma0) >> 48)
  if (r & 0x80000000UL) == 0UL {
    0x80000000U
  } else {
    r.to_uint()
  }
}
