pub(readonly) type T UInt

pub fn new() -> T {
  return 0x00000000
}

pub fn set_nth(self : T, n : Int) -> T {
  // assert n >= 0
  self._.lor(0x80000000U >> n)
}

pub fn unset_nth(self : T, n : Int) -> T {
  self._.land((0x80000000U >> n).lnot())
}

test "set and unset bitvector32" {
  let zero_v = 0x00000000U
  let one_v = 0xFFFFFFFFU

  for n = 0; n < 32; n = n + 1 {
    let r = T(zero_v).set_nth(n).unset_nth(n)
    assert_eq!(r._, zero_v)
  }
  for n = 0; n < 32; n = n + 1 {
    let r = T(one_v).unset_nth(n).set_nth(n)
    assert_eq!(r._, one_v)
  }
  for n = 0; n < 32; n = n + 1 {
    let r = T(zero_v).set_nth(n)
    assert_eq!(r._.clz(), n)
    assert_eq!(r._.popcnt(), 1)
  }
  for n = 0; n < 32; n = n + 1 {
    let r = T(one_v).unset_nth(n)
    assert_eq!(r._.popcnt(), 31)
  }
}