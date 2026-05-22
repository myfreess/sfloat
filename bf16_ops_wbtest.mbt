///|
test "bf16_to_f32 widens finite values and infinities" {
  let context = Context::default()
  let one = BF16::from_bits(0x3F80).to_f32(context)
  @debug.assert_eq(one.value.to_bits(), 0x3F800000U)
  assert_flags(one.context, 0U)
  let subnormal = bf16_to_f32(context, BF16::from_bits(0x0001))
  @debug.assert_eq(subnormal.value.to_bits(), 0x00010000U)
  assert_flags(subnormal.context, 0U)
  let neg_inf = BF16::from_bits(0xFF80).to_f32(context)
  @debug.assert_eq(neg_inf.value.to_bits(), 0xFF800000U)
  assert_flags(neg_inf.context, 0U)
}

///|
test "bf16_to_f32 propagates nan by specialization" {
  let x86 = BF16::from_bits(0x7F81).to_f32(Context::default())
  @debug.assert_eq(x86.value.to_bits(), 0x7FC08000U)
  assert_flags(x86.context, ExceptionFlags::invalid().to_bits())
  let riscv = BF16::from_bits(0x7F81).to_f32(Context::riscv())
  @debug.assert_eq(riscv.value.to_bits(), 0x7FC00000U)
  assert_flags(riscv.context, ExceptionFlags::invalid().to_bits())
}

///|
test "f32_to_bf16 rounds finite values and preserves flags" {
  let context = Context::default()
  let one = F32::from_bits(0x3F800000U).to_bf16(context)
  @debug.assert_eq(one.value.to_bits(), 0x3F80)
  assert_flags(one.context, 0U)

  let tiny_round = f32_to_bf16(context, F32::from_bits(0x3F800001U))
  @debug.assert_eq(tiny_round.value.to_bits(), 0x3F80)
  assert_flags(tiny_round.context, ExceptionFlags::inexact().to_bits())

  let up = F32::from_bits(0x3F80FFFFU).to_bf16(context)
  @debug.assert_eq(up.value.to_bits(), 0x3F81)
  assert_flags(up.context, ExceptionFlags::inexact().to_bits())
}

///|
test "f32_to_bf16 handles infinities and nan specialization" {
  let context = Context::default()
  let inf = F32::from_bits(0x7F800000U).to_bf16(context)
  @debug.assert_eq(inf.value.to_bits(), 0x7F80)
  assert_flags(inf.context, 0U)

  let x86 = F32::from_bits(0x7F800001U).to_bf16(context)
  @debug.assert_eq(x86.value.to_bits(), 0x7FC0)
  assert_flags(x86.context, ExceptionFlags::invalid().to_bits())
  let riscv = F32::from_bits(0x7F800001U).to_bf16(Context::riscv())
  @debug.assert_eq(riscv.value.to_bits(), 0x7FC0)
  assert_flags(riscv.context, ExceptionFlags::invalid().to_bits())
  @debug.assert_eq(bf16_is_signaling_nan(BF16::from_bits(0x7F81)), true)
}
