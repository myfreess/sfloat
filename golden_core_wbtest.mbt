///|
test "golden core vectors match committed C oracle records" {
  // x86_8086_sse ui32_to_f16 near_even after 1 00000001 3C00 00
  let result0 = ui32_to_f16(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    0x00000001U,
  )
  @debug.assert_eq(result0.value.to_bits(), 0x3C00)
  @debug.assert_eq(result0.context.flags.to_bits(), 0x00U)
  // riscv ui32_to_f16 near_even after 1 00000001 3C00 00
  let result1 = ui32_to_f16(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    0x00000001U,
  )
  @debug.assert_eq(result1.value.to_bits(), 0x3C00)
  @debug.assert_eq(result1.context.flags.to_bits(), 0x00U)
  // x86_8086_sse ui32_to_f32 near_even after 1 00000001 3F800000 00
  let result2 = ui32_to_f32(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    0x00000001U,
  )
  @debug.assert_eq(result2.value.to_bits(), 0x3F800000U)
  @debug.assert_eq(result2.context.flags.to_bits(), 0x00U)
  // riscv ui32_to_f32 near_even after 1 00000001 3F800000 00
  let result3 = ui32_to_f32(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    0x00000001U,
  )
  @debug.assert_eq(result3.value.to_bits(), 0x3F800000U)
  @debug.assert_eq(result3.context.flags.to_bits(), 0x00U)
  // x86_8086_sse ui32_to_f64 near_even after 1 00000001 3FF0000000000000 00
  let result4 = ui32_to_f64(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    0x00000001U,
  )
  @debug.assert_eq(result4.value.to_bits(), 0x3FF0000000000000UL)
  @debug.assert_eq(result4.context.flags.to_bits(), 0x00U)
  // riscv ui32_to_f64 near_even after 1 00000001 3FF0000000000000 00
  let result5 = ui32_to_f64(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    0x00000001U,
  )
  @debug.assert_eq(result5.value.to_bits(), 0x3FF0000000000000UL)
  @debug.assert_eq(result5.context.flags.to_bits(), 0x00U)
  // x86_8086_sse ui64_to_f16 near_even after 1 0000000000000001 3C00 00
  let result6 = ui64_to_f16(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    0x0000000000000001UL,
  )
  @debug.assert_eq(result6.value.to_bits(), 0x3C00)
  @debug.assert_eq(result6.context.flags.to_bits(), 0x00U)
  // riscv ui64_to_f16 near_even after 1 0000000000000001 3C00 00
  let result7 = ui64_to_f16(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    0x0000000000000001UL,
  )
  @debug.assert_eq(result7.value.to_bits(), 0x3C00)
  @debug.assert_eq(result7.context.flags.to_bits(), 0x00U)
  // x86_8086_sse ui64_to_f32 near_even after 1 0000000000000001 3F800000 00
  let result8 = ui64_to_f32(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    0x0000000000000001UL,
  )
  @debug.assert_eq(result8.value.to_bits(), 0x3F800000U)
  @debug.assert_eq(result8.context.flags.to_bits(), 0x00U)
  // riscv ui64_to_f32 near_even after 1 0000000000000001 3F800000 00
  let result9 = ui64_to_f32(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    0x0000000000000001UL,
  )
  @debug.assert_eq(result9.value.to_bits(), 0x3F800000U)
  @debug.assert_eq(result9.context.flags.to_bits(), 0x00U)
  // x86_8086_sse ui64_to_f64 near_even after 1 0000000000000001 3FF0000000000000 00
  let result10 = ui64_to_f64(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    0x0000000000000001UL,
  )
  @debug.assert_eq(result10.value.to_bits(), 0x3FF0000000000000UL)
  @debug.assert_eq(result10.context.flags.to_bits(), 0x00U)
  // riscv ui64_to_f64 near_even after 1 0000000000000001 3FF0000000000000 00
  let result11 = ui64_to_f64(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    0x0000000000000001UL,
  )
  @debug.assert_eq(result11.value.to_bits(), 0x3FF0000000000000UL)
  @debug.assert_eq(result11.context.flags.to_bits(), 0x00U)
  // x86_8086_sse i32_to_f16 near_even after 1 FFFFFFFF BC00 00
  let result12 = i32_to_f16(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    0xFFFFFFFFU.reinterpret_as_int(),
  )
  @debug.assert_eq(result12.value.to_bits(), 0xBC00)
  @debug.assert_eq(result12.context.flags.to_bits(), 0x00U)
  // riscv i32_to_f16 near_even after 1 FFFFFFFF BC00 00
  let result13 = i32_to_f16(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    0xFFFFFFFFU.reinterpret_as_int(),
  )
  @debug.assert_eq(result13.value.to_bits(), 0xBC00)
  @debug.assert_eq(result13.context.flags.to_bits(), 0x00U)
  // x86_8086_sse i32_to_f32 near_even after 1 FFFFFFFF BF800000 00
  let result14 = i32_to_f32(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    0xFFFFFFFFU.reinterpret_as_int(),
  )
  @debug.assert_eq(result14.value.to_bits(), 0xBF800000U)
  @debug.assert_eq(result14.context.flags.to_bits(), 0x00U)
  // riscv i32_to_f32 near_even after 1 FFFFFFFF BF800000 00
  let result15 = i32_to_f32(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    0xFFFFFFFFU.reinterpret_as_int(),
  )
  @debug.assert_eq(result15.value.to_bits(), 0xBF800000U)
  @debug.assert_eq(result15.context.flags.to_bits(), 0x00U)
  // x86_8086_sse i32_to_f64 near_even after 1 FFFFFFFF BFF0000000000000 00
  let result16 = i32_to_f64(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    0xFFFFFFFFU.reinterpret_as_int(),
  )
  @debug.assert_eq(result16.value.to_bits(), 0xBFF0000000000000UL)
  @debug.assert_eq(result16.context.flags.to_bits(), 0x00U)
  // riscv i32_to_f64 near_even after 1 FFFFFFFF BFF0000000000000 00
  let result17 = i32_to_f64(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    0xFFFFFFFFU.reinterpret_as_int(),
  )
  @debug.assert_eq(result17.value.to_bits(), 0xBFF0000000000000UL)
  @debug.assert_eq(result17.context.flags.to_bits(), 0x00U)
  // x86_8086_sse i64_to_f16 near_even after 1 FFFFFFFFFFFFFFFF BC00 00
  let result18 = i64_to_f16(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    0xFFFFFFFFFFFFFFFFUL.reinterpret_as_int64(),
  )
  @debug.assert_eq(result18.value.to_bits(), 0xBC00)
  @debug.assert_eq(result18.context.flags.to_bits(), 0x00U)
  // riscv i64_to_f16 near_even after 1 FFFFFFFFFFFFFFFF BC00 00
  let result19 = i64_to_f16(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    0xFFFFFFFFFFFFFFFFUL.reinterpret_as_int64(),
  )
  @debug.assert_eq(result19.value.to_bits(), 0xBC00)
  @debug.assert_eq(result19.context.flags.to_bits(), 0x00U)
  // x86_8086_sse i64_to_f32 near_even after 1 FFFFFFFFFFFFFFFF BF800000 00
  let result20 = i64_to_f32(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    0xFFFFFFFFFFFFFFFFUL.reinterpret_as_int64(),
  )
  @debug.assert_eq(result20.value.to_bits(), 0xBF800000U)
  @debug.assert_eq(result20.context.flags.to_bits(), 0x00U)
  // riscv i64_to_f32 near_even after 1 FFFFFFFFFFFFFFFF BF800000 00
  let result21 = i64_to_f32(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    0xFFFFFFFFFFFFFFFFUL.reinterpret_as_int64(),
  )
  @debug.assert_eq(result21.value.to_bits(), 0xBF800000U)
  @debug.assert_eq(result21.context.flags.to_bits(), 0x00U)
  // x86_8086_sse i64_to_f64 near_even after 1 FFFFFFFFFFFFFFFF BFF0000000000000 00
  let result22 = i64_to_f64(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    0xFFFFFFFFFFFFFFFFUL.reinterpret_as_int64(),
  )
  @debug.assert_eq(result22.value.to_bits(), 0xBFF0000000000000UL)
  @debug.assert_eq(result22.context.flags.to_bits(), 0x00U)
  // riscv i64_to_f64 near_even after 1 FFFFFFFFFFFFFFFF BFF0000000000000 00
  let result23 = i64_to_f64(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    0xFFFFFFFFFFFFFFFFUL.reinterpret_as_int64(),
  )
  @debug.assert_eq(result23.value.to_bits(), 0xBFF0000000000000UL)
  @debug.assert_eq(result23.context.flags.to_bits(), 0x00U)
  // x86_8086_sse bf16_to_f32 near_even after 1 3F80 3F800000 00
  let result24 = bf16_to_f32(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    BF16::from_bits(0x3F80),
  )
  @debug.assert_eq(result24.value.to_bits(), 0x3F800000U)
  @debug.assert_eq(result24.context.flags.to_bits(), 0x00U)
  // riscv bf16_to_f32 near_even after 1 3F80 3F800000 00
  let result25 = bf16_to_f32(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    BF16::from_bits(0x3F80),
  )
  @debug.assert_eq(result25.value.to_bits(), 0x3F800000U)
  @debug.assert_eq(result25.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f32_to_bf16 near_even after 1 3F800000 3F80 00
  let result26 = f32_to_bf16(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result26.value.to_bits(), 0x3F80)
  @debug.assert_eq(result26.context.flags.to_bits(), 0x00U)
  // riscv f32_to_bf16 near_even after 1 3F800000 3F80 00
  let result27 = f32_to_bf16(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result27.value.to_bits(), 0x3F80)
  @debug.assert_eq(result27.context.flags.to_bits(), 0x00U)
  // x86_8086_sse bf16_is_signaling_nan near_even after 1 7F81 1 00
  let result28 = bf16_is_signaling_nan(BF16::from_bits(0x7F81))
  @debug.assert_eq(result28, true)
  @debug.assert_eq(0U, 0x00U)
  // riscv bf16_is_signaling_nan near_even after 1 7F81 1 00
  let result29 = bf16_is_signaling_nan(BF16::from_bits(0x7F81))
  @debug.assert_eq(result29, true)
  @debug.assert_eq(0U, 0x00U)
  // x86_8086_sse f16_to_ui32 near_even after 1 3E00 00000002 01
  let result30 = f16_to_ui32(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    NearEven,
    true,
  )
  @debug.assert_eq(result30.value, 0x00000002U)
  @debug.assert_eq(result30.context.flags.to_bits(), 0x01U)
  // riscv f16_to_ui32 near_even after 1 3E00 00000002 01
  let result31 = f16_to_ui32(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    NearEven,
    true,
  )
  @debug.assert_eq(result31.value, 0x00000002U)
  @debug.assert_eq(result31.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f16_to_ui64 near_even after 1 3E00 0000000000000002 01
  let result32 = f16_to_ui64(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    NearEven,
    true,
  )
  @debug.assert_eq(result32.value, 0x0000000000000002UL)
  @debug.assert_eq(result32.context.flags.to_bits(), 0x01U)
  // riscv f16_to_ui64 near_even after 1 3E00 0000000000000002 01
  let result33 = f16_to_ui64(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    NearEven,
    true,
  )
  @debug.assert_eq(result33.value, 0x0000000000000002UL)
  @debug.assert_eq(result33.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f16_to_i32 near_even after 1 3E00 00000002 01
  let result34 = f16_to_i32(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    NearEven,
    true,
  )
  @debug.assert_eq(result34.value, 0x00000002U.reinterpret_as_int())
  @debug.assert_eq(result34.context.flags.to_bits(), 0x01U)
  // riscv f16_to_i32 near_even after 1 3E00 00000002 01
  let result35 = f16_to_i32(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    NearEven,
    true,
  )
  @debug.assert_eq(result35.value, 0x00000002U.reinterpret_as_int())
  @debug.assert_eq(result35.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f16_to_i64 near_even after 1 3E00 0000000000000002 01
  let result36 = f16_to_i64(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    NearEven,
    true,
  )
  @debug.assert_eq(result36.value, 0x0000000000000002UL.reinterpret_as_int64())
  @debug.assert_eq(result36.context.flags.to_bits(), 0x01U)
  // riscv f16_to_i64 near_even after 1 3E00 0000000000000002 01
  let result37 = f16_to_i64(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    NearEven,
    true,
  )
  @debug.assert_eq(result37.value, 0x0000000000000002UL.reinterpret_as_int64())
  @debug.assert_eq(result37.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f16_to_ui32_min_mag near_even after 1 3E00 00000001 01
  let result38 = f16_to_ui32_min_mag(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    true,
  )
  @debug.assert_eq(result38.value, 0x00000001U)
  @debug.assert_eq(result38.context.flags.to_bits(), 0x01U)
  // riscv f16_to_ui32_min_mag near_even after 1 3E00 00000001 01
  let result39 = f16_to_ui32_min_mag(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    true,
  )
  @debug.assert_eq(result39.value, 0x00000001U)
  @debug.assert_eq(result39.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f16_to_ui64_min_mag near_even after 1 3E00 0000000000000001 01
  let result40 = f16_to_ui64_min_mag(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    true,
  )
  @debug.assert_eq(result40.value, 0x0000000000000001UL)
  @debug.assert_eq(result40.context.flags.to_bits(), 0x01U)
  // riscv f16_to_ui64_min_mag near_even after 1 3E00 0000000000000001 01
  let result41 = f16_to_ui64_min_mag(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    true,
  )
  @debug.assert_eq(result41.value, 0x0000000000000001UL)
  @debug.assert_eq(result41.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f16_to_i32_min_mag near_even after 1 3E00 00000001 01
  let result42 = f16_to_i32_min_mag(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    true,
  )
  @debug.assert_eq(result42.value, 0x00000001U.reinterpret_as_int())
  @debug.assert_eq(result42.context.flags.to_bits(), 0x01U)
  // riscv f16_to_i32_min_mag near_even after 1 3E00 00000001 01
  let result43 = f16_to_i32_min_mag(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    true,
  )
  @debug.assert_eq(result43.value, 0x00000001U.reinterpret_as_int())
  @debug.assert_eq(result43.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f16_to_i64_min_mag near_even after 1 3E00 0000000000000001 01
  let result44 = f16_to_i64_min_mag(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    true,
  )
  @debug.assert_eq(result44.value, 0x0000000000000001UL.reinterpret_as_int64())
  @debug.assert_eq(result44.context.flags.to_bits(), 0x01U)
  // riscv f16_to_i64_min_mag near_even after 1 3E00 0000000000000001 01
  let result45 = f16_to_i64_min_mag(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    true,
  )
  @debug.assert_eq(result45.value, 0x0000000000000001UL.reinterpret_as_int64())
  @debug.assert_eq(result45.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f16_to_f32 near_even after 1 3C00 3F800000 00
  let result46 = f16_to_f32(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result46.value.to_bits(), 0x3F800000U)
  @debug.assert_eq(result46.context.flags.to_bits(), 0x00U)
  // riscv f16_to_f32 near_even after 1 3C00 3F800000 00
  let result47 = f16_to_f32(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result47.value.to_bits(), 0x3F800000U)
  @debug.assert_eq(result47.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f16_to_f64 near_even after 1 3C00 3FF0000000000000 00
  let result48 = f16_to_f64(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result48.value.to_bits(), 0x3FF0000000000000UL)
  @debug.assert_eq(result48.context.flags.to_bits(), 0x00U)
  // riscv f16_to_f64 near_even after 1 3C00 3FF0000000000000 00
  let result49 = f16_to_f64(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result49.value.to_bits(), 0x3FF0000000000000UL)
  @debug.assert_eq(result49.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f16_round_to_int near_even after 1 3E00 4000 01
  let result50 = f16_round_to_int(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    NearEven,
    true,
  )
  @debug.assert_eq(result50.value.to_bits(), 0x4000)
  @debug.assert_eq(result50.context.flags.to_bits(), 0x01U)
  // riscv f16_round_to_int near_even after 1 3E00 4000 01
  let result51 = f16_round_to_int(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3E00),
    NearEven,
    true,
  )
  @debug.assert_eq(result51.value.to_bits(), 0x4000)
  @debug.assert_eq(result51.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f16_add near_even after 1 3C00 3C00 4000 00
  let result52 = f16_add(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3C00),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result52.value.to_bits(), 0x4000)
  @debug.assert_eq(result52.context.flags.to_bits(), 0x00U)
  // riscv f16_add near_even after 1 3C00 3C00 4000 00
  let result53 = f16_add(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3C00),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result53.value.to_bits(), 0x4000)
  @debug.assert_eq(result53.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f16_sub near_even after 1 4000 3C00 3C00 00
  let result54 = f16_sub(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x4000),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result54.value.to_bits(), 0x3C00)
  @debug.assert_eq(result54.context.flags.to_bits(), 0x00U)
  // riscv f16_sub near_even after 1 4000 3C00 3C00 00
  let result55 = f16_sub(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x4000),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result55.value.to_bits(), 0x3C00)
  @debug.assert_eq(result55.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f16_mul near_even after 1 3C00 4000 4000 00
  let result56 = f16_mul(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3C00),
    F16::from_bits(0x4000),
  )
  @debug.assert_eq(result56.value.to_bits(), 0x4000)
  @debug.assert_eq(result56.context.flags.to_bits(), 0x00U)
  // riscv f16_mul near_even after 1 3C00 4000 4000 00
  let result57 = f16_mul(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3C00),
    F16::from_bits(0x4000),
  )
  @debug.assert_eq(result57.value.to_bits(), 0x4000)
  @debug.assert_eq(result57.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f16_mul_add near_even after 1 4000 4200 3C00 4700 00
  let result58 = f16_mul_add(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x4000),
    F16::from_bits(0x4200),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result58.value.to_bits(), 0x4700)
  @debug.assert_eq(result58.context.flags.to_bits(), 0x00U)
  // riscv f16_mul_add near_even after 1 4000 4200 3C00 4700 00
  let result59 = f16_mul_add(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x4000),
    F16::from_bits(0x4200),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result59.value.to_bits(), 0x4700)
  @debug.assert_eq(result59.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f16_div near_even after 1 3C00 4000 3800 00
  let result60 = f16_div(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3C00),
    F16::from_bits(0x4000),
  )
  @debug.assert_eq(result60.value.to_bits(), 0x3800)
  @debug.assert_eq(result60.context.flags.to_bits(), 0x00U)
  // riscv f16_div near_even after 1 3C00 4000 3800 00
  let result61 = f16_div(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3C00),
    F16::from_bits(0x4000),
  )
  @debug.assert_eq(result61.value.to_bits(), 0x3800)
  @debug.assert_eq(result61.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f16_rem near_even after 1 4500 4000 3C00 00
  let result62 = f16_rem(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x4500),
    F16::from_bits(0x4000),
  )
  @debug.assert_eq(result62.value.to_bits(), 0x3C00)
  @debug.assert_eq(result62.context.flags.to_bits(), 0x00U)
  // riscv f16_rem near_even after 1 4500 4000 3C00 00
  let result63 = f16_rem(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x4500),
    F16::from_bits(0x4000),
  )
  @debug.assert_eq(result63.value.to_bits(), 0x3C00)
  @debug.assert_eq(result63.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f16_sqrt near_even after 1 4000 3DA8 01
  let result64 = f16_sqrt(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x4000),
  )
  @debug.assert_eq(result64.value.to_bits(), 0x3DA8)
  @debug.assert_eq(result64.context.flags.to_bits(), 0x01U)
  // riscv f16_sqrt near_even after 1 4000 3DA8 01
  let result65 = f16_sqrt(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x4000),
  )
  @debug.assert_eq(result65.value.to_bits(), 0x3DA8)
  @debug.assert_eq(result65.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f16_eq near_even after 1 8000 0000 1 00
  let result66 = f16_eq(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x8000),
    F16::from_bits(0x0000),
  )
  @debug.assert_eq(result66.value, true)
  @debug.assert_eq(result66.context.flags.to_bits(), 0x00U)
  // riscv f16_eq near_even after 1 8000 0000 1 00
  let result67 = f16_eq(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x8000),
    F16::from_bits(0x0000),
  )
  @debug.assert_eq(result67.value, true)
  @debug.assert_eq(result67.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f16_le near_even after 1 3C00 4000 1 00
  let result68 = f16_le(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3C00),
    F16::from_bits(0x4000),
  )
  @debug.assert_eq(result68.value, true)
  @debug.assert_eq(result68.context.flags.to_bits(), 0x00U)
  // riscv f16_le near_even after 1 3C00 4000 1 00
  let result69 = f16_le(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3C00),
    F16::from_bits(0x4000),
  )
  @debug.assert_eq(result69.value, true)
  @debug.assert_eq(result69.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f16_lt near_even after 1 3C00 4000 1 00
  let result70 = f16_lt(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3C00),
    F16::from_bits(0x4000),
  )
  @debug.assert_eq(result70.value, true)
  @debug.assert_eq(result70.context.flags.to_bits(), 0x00U)
  // riscv f16_lt near_even after 1 3C00 4000 1 00
  let result71 = f16_lt(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x3C00),
    F16::from_bits(0x4000),
  )
  @debug.assert_eq(result71.value, true)
  @debug.assert_eq(result71.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f16_eq_signaling near_even after 1 7E00 3C00 0 10
  let result72 = f16_eq_signaling(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x7E00),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result72.value, false)
  @debug.assert_eq(result72.context.flags.to_bits(), 0x10U)
  // riscv f16_eq_signaling near_even after 1 7E00 3C00 0 10
  let result73 = f16_eq_signaling(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x7E00),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result73.value, false)
  @debug.assert_eq(result73.context.flags.to_bits(), 0x10U)
  // x86_8086_sse f16_le_quiet near_even after 1 7C01 3C00 0 10
  let result74 = f16_le_quiet(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x7C01),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result74.value, false)
  @debug.assert_eq(result74.context.flags.to_bits(), 0x10U)
  // riscv f16_le_quiet near_even after 1 7C01 3C00 0 10
  let result75 = f16_le_quiet(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x7C01),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result75.value, false)
  @debug.assert_eq(result75.context.flags.to_bits(), 0x10U)
  // x86_8086_sse f16_lt_quiet near_even after 1 7C01 3C00 0 10
  let result76 = f16_lt_quiet(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x7C01),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result76.value, false)
  @debug.assert_eq(result76.context.flags.to_bits(), 0x10U)
  // riscv f16_lt_quiet near_even after 1 7C01 3C00 0 10
  let result77 = f16_lt_quiet(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F16::from_bits(0x7C01),
    F16::from_bits(0x3C00),
  )
  @debug.assert_eq(result77.value, false)
  @debug.assert_eq(result77.context.flags.to_bits(), 0x10U)
  // x86_8086_sse f16_is_signaling_nan near_even after 1 7C01 1 00
  let result78 = f16_is_signaling_nan(F16::from_bits(0x7C01))
  @debug.assert_eq(result78, true)
  @debug.assert_eq(0U, 0x00U)
  // riscv f16_is_signaling_nan near_even after 1 7C01 1 00
  let result79 = f16_is_signaling_nan(F16::from_bits(0x7C01))
  @debug.assert_eq(result79, true)
  @debug.assert_eq(0U, 0x00U)
  // x86_8086_sse f32_to_ui32 near_even after 1 3FC00000 00000002 01
  let result80 = f32_to_ui32(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    NearEven,
    true,
  )
  @debug.assert_eq(result80.value, 0x00000002U)
  @debug.assert_eq(result80.context.flags.to_bits(), 0x01U)
  // riscv f32_to_ui32 near_even after 1 3FC00000 00000002 01
  let result81 = f32_to_ui32(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    NearEven,
    true,
  )
  @debug.assert_eq(result81.value, 0x00000002U)
  @debug.assert_eq(result81.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f32_to_ui64 near_even after 1 3FC00000 0000000000000002 01
  let result82 = f32_to_ui64(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    NearEven,
    true,
  )
  @debug.assert_eq(result82.value, 0x0000000000000002UL)
  @debug.assert_eq(result82.context.flags.to_bits(), 0x01U)
  // riscv f32_to_ui64 near_even after 1 3FC00000 0000000000000002 01
  let result83 = f32_to_ui64(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    NearEven,
    true,
  )
  @debug.assert_eq(result83.value, 0x0000000000000002UL)
  @debug.assert_eq(result83.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f32_to_i32 near_even after 1 3FC00000 00000002 01
  let result84 = f32_to_i32(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    NearEven,
    true,
  )
  @debug.assert_eq(result84.value, 0x00000002U.reinterpret_as_int())
  @debug.assert_eq(result84.context.flags.to_bits(), 0x01U)
  // riscv f32_to_i32 near_even after 1 3FC00000 00000002 01
  let result85 = f32_to_i32(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    NearEven,
    true,
  )
  @debug.assert_eq(result85.value, 0x00000002U.reinterpret_as_int())
  @debug.assert_eq(result85.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f32_to_i64 near_even after 1 3FC00000 0000000000000002 01
  let result86 = f32_to_i64(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    NearEven,
    true,
  )
  @debug.assert_eq(result86.value, 0x0000000000000002UL.reinterpret_as_int64())
  @debug.assert_eq(result86.context.flags.to_bits(), 0x01U)
  // riscv f32_to_i64 near_even after 1 3FC00000 0000000000000002 01
  let result87 = f32_to_i64(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    NearEven,
    true,
  )
  @debug.assert_eq(result87.value, 0x0000000000000002UL.reinterpret_as_int64())
  @debug.assert_eq(result87.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f32_to_ui32_min_mag near_even after 1 3FC00000 00000001 01
  let result88 = f32_to_ui32_min_mag(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    true,
  )
  @debug.assert_eq(result88.value, 0x00000001U)
  @debug.assert_eq(result88.context.flags.to_bits(), 0x01U)
  // riscv f32_to_ui32_min_mag near_even after 1 3FC00000 00000001 01
  let result89 = f32_to_ui32_min_mag(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    true,
  )
  @debug.assert_eq(result89.value, 0x00000001U)
  @debug.assert_eq(result89.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f32_to_ui64_min_mag near_even after 1 3FC00000 0000000000000001 01
  let result90 = f32_to_ui64_min_mag(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    true,
  )
  @debug.assert_eq(result90.value, 0x0000000000000001UL)
  @debug.assert_eq(result90.context.flags.to_bits(), 0x01U)
  // riscv f32_to_ui64_min_mag near_even after 1 3FC00000 0000000000000001 01
  let result91 = f32_to_ui64_min_mag(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    true,
  )
  @debug.assert_eq(result91.value, 0x0000000000000001UL)
  @debug.assert_eq(result91.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f32_to_i32_min_mag near_even after 1 3FC00000 00000001 01
  let result92 = f32_to_i32_min_mag(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    true,
  )
  @debug.assert_eq(result92.value, 0x00000001U.reinterpret_as_int())
  @debug.assert_eq(result92.context.flags.to_bits(), 0x01U)
  // riscv f32_to_i32_min_mag near_even after 1 3FC00000 00000001 01
  let result93 = f32_to_i32_min_mag(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    true,
  )
  @debug.assert_eq(result93.value, 0x00000001U.reinterpret_as_int())
  @debug.assert_eq(result93.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f32_to_i64_min_mag near_even after 1 3FC00000 0000000000000001 01
  let result94 = f32_to_i64_min_mag(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    true,
  )
  @debug.assert_eq(result94.value, 0x0000000000000001UL.reinterpret_as_int64())
  @debug.assert_eq(result94.context.flags.to_bits(), 0x01U)
  // riscv f32_to_i64_min_mag near_even after 1 3FC00000 0000000000000001 01
  let result95 = f32_to_i64_min_mag(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    true,
  )
  @debug.assert_eq(result95.value, 0x0000000000000001UL.reinterpret_as_int64())
  @debug.assert_eq(result95.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f32_to_f16 near_even after 1 3F800000 3C00 00
  let result96 = f32_to_f16(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result96.value.to_bits(), 0x3C00)
  @debug.assert_eq(result96.context.flags.to_bits(), 0x00U)
  // riscv f32_to_f16 near_even after 1 3F800000 3C00 00
  let result97 = f32_to_f16(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result97.value.to_bits(), 0x3C00)
  @debug.assert_eq(result97.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f32_to_f64 near_even after 1 3F800000 3FF0000000000000 00
  let result98 = f32_to_f64(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result98.value.to_bits(), 0x3FF0000000000000UL)
  @debug.assert_eq(result98.context.flags.to_bits(), 0x00U)
  // riscv f32_to_f64 near_even after 1 3F800000 3FF0000000000000 00
  let result99 = f32_to_f64(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result99.value.to_bits(), 0x3FF0000000000000UL)
  @debug.assert_eq(result99.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f32_round_to_int near_even after 1 3FC00000 40000000 01
  let result100 = f32_round_to_int(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    NearEven,
    true,
  )
  @debug.assert_eq(result100.value.to_bits(), 0x40000000U)
  @debug.assert_eq(result100.context.flags.to_bits(), 0x01U)
  // riscv f32_round_to_int near_even after 1 3FC00000 40000000 01
  let result101 = f32_round_to_int(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3FC00000U),
    NearEven,
    true,
  )
  @debug.assert_eq(result101.value.to_bits(), 0x40000000U)
  @debug.assert_eq(result101.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f32_add near_even after 1 3F800000 3F800000 40000000 00
  let result102 = f32_add(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result102.value.to_bits(), 0x40000000U)
  @debug.assert_eq(result102.context.flags.to_bits(), 0x00U)
  // riscv f32_add near_even after 1 3F800000 3F800000 40000000 00
  let result103 = f32_add(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result103.value.to_bits(), 0x40000000U)
  @debug.assert_eq(result103.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f32_sub near_even after 1 40000000 3F800000 3F800000 00
  let result104 = f32_sub(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x40000000U),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result104.value.to_bits(), 0x3F800000U)
  @debug.assert_eq(result104.context.flags.to_bits(), 0x00U)
  // riscv f32_sub near_even after 1 40000000 3F800000 3F800000 00
  let result105 = f32_sub(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x40000000U),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result105.value.to_bits(), 0x3F800000U)
  @debug.assert_eq(result105.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f32_mul near_even after 1 3F800000 40000000 40000000 00
  let result106 = f32_mul(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
    F32::from_bits(0x40000000U),
  )
  @debug.assert_eq(result106.value.to_bits(), 0x40000000U)
  @debug.assert_eq(result106.context.flags.to_bits(), 0x00U)
  // riscv f32_mul near_even after 1 3F800000 40000000 40000000 00
  let result107 = f32_mul(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
    F32::from_bits(0x40000000U),
  )
  @debug.assert_eq(result107.value.to_bits(), 0x40000000U)
  @debug.assert_eq(result107.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f32_mul_add near_even after 1 40000000 40400000 3F800000 40E00000 00
  let result108 = f32_mul_add(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x40000000U),
    F32::from_bits(0x40400000U),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result108.value.to_bits(), 0x40E00000U)
  @debug.assert_eq(result108.context.flags.to_bits(), 0x00U)
  // riscv f32_mul_add near_even after 1 40000000 40400000 3F800000 40E00000 00
  let result109 = f32_mul_add(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x40000000U),
    F32::from_bits(0x40400000U),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result109.value.to_bits(), 0x40E00000U)
  @debug.assert_eq(result109.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f32_div near_even after 1 3F800000 40400000 3EAAAAAB 01
  let result110 = f32_div(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
    F32::from_bits(0x40400000U),
  )
  @debug.assert_eq(result110.value.to_bits(), 0x3EAAAAABU)
  @debug.assert_eq(result110.context.flags.to_bits(), 0x01U)
  // riscv f32_div near_even after 1 3F800000 40400000 3EAAAAAB 01
  let result111 = f32_div(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
    F32::from_bits(0x40400000U),
  )
  @debug.assert_eq(result111.value.to_bits(), 0x3EAAAAABU)
  @debug.assert_eq(result111.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f32_rem near_even after 1 40A00000 40000000 3F800000 00
  let result112 = f32_rem(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x40A00000U),
    F32::from_bits(0x40000000U),
  )
  @debug.assert_eq(result112.value.to_bits(), 0x3F800000U)
  @debug.assert_eq(result112.context.flags.to_bits(), 0x00U)
  // riscv f32_rem near_even after 1 40A00000 40000000 3F800000 00
  let result113 = f32_rem(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x40A00000U),
    F32::from_bits(0x40000000U),
  )
  @debug.assert_eq(result113.value.to_bits(), 0x3F800000U)
  @debug.assert_eq(result113.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f32_sqrt near_even after 1 40000000 3FB504F3 01
  let result114 = f32_sqrt(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x40000000U),
  )
  @debug.assert_eq(result114.value.to_bits(), 0x3FB504F3U)
  @debug.assert_eq(result114.context.flags.to_bits(), 0x01U)
  // riscv f32_sqrt near_even after 1 40000000 3FB504F3 01
  let result115 = f32_sqrt(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x40000000U),
  )
  @debug.assert_eq(result115.value.to_bits(), 0x3FB504F3U)
  @debug.assert_eq(result115.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f32_eq near_even after 1 80000000 00000000 1 00
  let result116 = f32_eq(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x80000000U),
    F32::from_bits(0x00000000U),
  )
  @debug.assert_eq(result116.value, true)
  @debug.assert_eq(result116.context.flags.to_bits(), 0x00U)
  // riscv f32_eq near_even after 1 80000000 00000000 1 00
  let result117 = f32_eq(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x80000000U),
    F32::from_bits(0x00000000U),
  )
  @debug.assert_eq(result117.value, true)
  @debug.assert_eq(result117.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f32_le near_even after 1 3F800000 40000000 1 00
  let result118 = f32_le(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
    F32::from_bits(0x40000000U),
  )
  @debug.assert_eq(result118.value, true)
  @debug.assert_eq(result118.context.flags.to_bits(), 0x00U)
  // riscv f32_le near_even after 1 3F800000 40000000 1 00
  let result119 = f32_le(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
    F32::from_bits(0x40000000U),
  )
  @debug.assert_eq(result119.value, true)
  @debug.assert_eq(result119.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f32_lt near_even after 1 3F800000 40000000 1 00
  let result120 = f32_lt(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
    F32::from_bits(0x40000000U),
  )
  @debug.assert_eq(result120.value, true)
  @debug.assert_eq(result120.context.flags.to_bits(), 0x00U)
  // riscv f32_lt near_even after 1 3F800000 40000000 1 00
  let result121 = f32_lt(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x3F800000U),
    F32::from_bits(0x40000000U),
  )
  @debug.assert_eq(result121.value, true)
  @debug.assert_eq(result121.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f32_eq_signaling near_even after 1 7FC00000 3F800000 0 10
  let result122 = f32_eq_signaling(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x7FC00000U),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result122.value, false)
  @debug.assert_eq(result122.context.flags.to_bits(), 0x10U)
  // riscv f32_eq_signaling near_even after 1 7FC00000 3F800000 0 10
  let result123 = f32_eq_signaling(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x7FC00000U),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result123.value, false)
  @debug.assert_eq(result123.context.flags.to_bits(), 0x10U)
  // x86_8086_sse f32_le_quiet near_even after 1 7F800001 3F800000 0 10
  let result124 = f32_le_quiet(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x7F800001U),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result124.value, false)
  @debug.assert_eq(result124.context.flags.to_bits(), 0x10U)
  // riscv f32_le_quiet near_even after 1 7F800001 3F800000 0 10
  let result125 = f32_le_quiet(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x7F800001U),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result125.value, false)
  @debug.assert_eq(result125.context.flags.to_bits(), 0x10U)
  // x86_8086_sse f32_lt_quiet near_even after 1 7F800001 3F800000 0 10
  let result126 = f32_lt_quiet(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x7F800001U),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result126.value, false)
  @debug.assert_eq(result126.context.flags.to_bits(), 0x10U)
  // riscv f32_lt_quiet near_even after 1 7F800001 3F800000 0 10
  let result127 = f32_lt_quiet(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F32::from_bits(0x7F800001U),
    F32::from_bits(0x3F800000U),
  )
  @debug.assert_eq(result127.value, false)
  @debug.assert_eq(result127.context.flags.to_bits(), 0x10U)
  // x86_8086_sse f32_is_signaling_nan near_even after 1 7F800001 1 00
  let result128 = f32_is_signaling_nan(F32::from_bits(0x7F800001U))
  @debug.assert_eq(result128, true)
  @debug.assert_eq(0U, 0x00U)
  // riscv f32_is_signaling_nan near_even after 1 7F800001 1 00
  let result129 = f32_is_signaling_nan(F32::from_bits(0x7F800001U))
  @debug.assert_eq(result129, true)
  @debug.assert_eq(0U, 0x00U)
  // x86_8086_sse f64_to_ui32 near_even after 1 3FF8000000000000 00000002 01
  let result130 = f64_to_ui32(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    NearEven,
    true,
  )
  @debug.assert_eq(result130.value, 0x00000002U)
  @debug.assert_eq(result130.context.flags.to_bits(), 0x01U)
  // riscv f64_to_ui32 near_even after 1 3FF8000000000000 00000002 01
  let result131 = f64_to_ui32(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    NearEven,
    true,
  )
  @debug.assert_eq(result131.value, 0x00000002U)
  @debug.assert_eq(result131.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f64_to_ui64 near_even after 1 3FF8000000000000 0000000000000002 01
  let result132 = f64_to_ui64(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    NearEven,
    true,
  )
  @debug.assert_eq(result132.value, 0x0000000000000002UL)
  @debug.assert_eq(result132.context.flags.to_bits(), 0x01U)
  // riscv f64_to_ui64 near_even after 1 3FF8000000000000 0000000000000002 01
  let result133 = f64_to_ui64(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    NearEven,
    true,
  )
  @debug.assert_eq(result133.value, 0x0000000000000002UL)
  @debug.assert_eq(result133.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f64_to_i32 near_even after 1 3FF8000000000000 00000002 01
  let result134 = f64_to_i32(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    NearEven,
    true,
  )
  @debug.assert_eq(result134.value, 0x00000002U.reinterpret_as_int())
  @debug.assert_eq(result134.context.flags.to_bits(), 0x01U)
  // riscv f64_to_i32 near_even after 1 3FF8000000000000 00000002 01
  let result135 = f64_to_i32(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    NearEven,
    true,
  )
  @debug.assert_eq(result135.value, 0x00000002U.reinterpret_as_int())
  @debug.assert_eq(result135.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f64_to_i64 near_even after 1 3FF8000000000000 0000000000000002 01
  let result136 = f64_to_i64(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    NearEven,
    true,
  )
  @debug.assert_eq(result136.value, 0x0000000000000002UL.reinterpret_as_int64())
  @debug.assert_eq(result136.context.flags.to_bits(), 0x01U)
  // riscv f64_to_i64 near_even after 1 3FF8000000000000 0000000000000002 01
  let result137 = f64_to_i64(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    NearEven,
    true,
  )
  @debug.assert_eq(result137.value, 0x0000000000000002UL.reinterpret_as_int64())
  @debug.assert_eq(result137.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f64_to_ui32_min_mag near_even after 1 3FF8000000000000 00000001 01
  let result138 = f64_to_ui32_min_mag(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    true,
  )
  @debug.assert_eq(result138.value, 0x00000001U)
  @debug.assert_eq(result138.context.flags.to_bits(), 0x01U)
  // riscv f64_to_ui32_min_mag near_even after 1 3FF8000000000000 00000001 01
  let result139 = f64_to_ui32_min_mag(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    true,
  )
  @debug.assert_eq(result139.value, 0x00000001U)
  @debug.assert_eq(result139.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f64_to_ui64_min_mag near_even after 1 3FF8000000000000 0000000000000001 01
  let result140 = f64_to_ui64_min_mag(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    true,
  )
  @debug.assert_eq(result140.value, 0x0000000000000001UL)
  @debug.assert_eq(result140.context.flags.to_bits(), 0x01U)
  // riscv f64_to_ui64_min_mag near_even after 1 3FF8000000000000 0000000000000001 01
  let result141 = f64_to_ui64_min_mag(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    true,
  )
  @debug.assert_eq(result141.value, 0x0000000000000001UL)
  @debug.assert_eq(result141.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f64_to_i32_min_mag near_even after 1 3FF8000000000000 00000001 01
  let result142 = f64_to_i32_min_mag(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    true,
  )
  @debug.assert_eq(result142.value, 0x00000001U.reinterpret_as_int())
  @debug.assert_eq(result142.context.flags.to_bits(), 0x01U)
  // riscv f64_to_i32_min_mag near_even after 1 3FF8000000000000 00000001 01
  let result143 = f64_to_i32_min_mag(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    true,
  )
  @debug.assert_eq(result143.value, 0x00000001U.reinterpret_as_int())
  @debug.assert_eq(result143.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f64_to_i64_min_mag near_even after 1 3FF8000000000000 0000000000000001 01
  let result144 = f64_to_i64_min_mag(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    true,
  )
  @debug.assert_eq(result144.value, 0x0000000000000001UL.reinterpret_as_int64())
  @debug.assert_eq(result144.context.flags.to_bits(), 0x01U)
  // riscv f64_to_i64_min_mag near_even after 1 3FF8000000000000 0000000000000001 01
  let result145 = f64_to_i64_min_mag(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    true,
  )
  @debug.assert_eq(result145.value, 0x0000000000000001UL.reinterpret_as_int64())
  @debug.assert_eq(result145.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f64_to_f16 near_even after 1 3FF0000000000000 3C00 00
  let result146 = f64_to_f16(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result146.value.to_bits(), 0x3C00)
  @debug.assert_eq(result146.context.flags.to_bits(), 0x00U)
  // riscv f64_to_f16 near_even after 1 3FF0000000000000 3C00 00
  let result147 = f64_to_f16(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result147.value.to_bits(), 0x3C00)
  @debug.assert_eq(result147.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f64_to_f32 near_even after 1 3FF0000000000000 3F800000 00
  let result148 = f64_to_f32(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result148.value.to_bits(), 0x3F800000U)
  @debug.assert_eq(result148.context.flags.to_bits(), 0x00U)
  // riscv f64_to_f32 near_even after 1 3FF0000000000000 3F800000 00
  let result149 = f64_to_f32(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result149.value.to_bits(), 0x3F800000U)
  @debug.assert_eq(result149.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f64_round_to_int near_even after 1 3FF8000000000000 4000000000000000 01
  let result150 = f64_round_to_int(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    NearEven,
    true,
  )
  @debug.assert_eq(result150.value.to_bits(), 0x4000000000000000UL)
  @debug.assert_eq(result150.context.flags.to_bits(), 0x01U)
  // riscv f64_round_to_int near_even after 1 3FF8000000000000 4000000000000000 01
  let result151 = f64_round_to_int(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF8000000000000UL),
    NearEven,
    true,
  )
  @debug.assert_eq(result151.value.to_bits(), 0x4000000000000000UL)
  @debug.assert_eq(result151.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f64_add near_even after 1 3FF0000000000000 3FF0000000000000 4000000000000000 00
  let result152 = f64_add(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF0000000000000UL),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result152.value.to_bits(), 0x4000000000000000UL)
  @debug.assert_eq(result152.context.flags.to_bits(), 0x00U)
  // riscv f64_add near_even after 1 3FF0000000000000 3FF0000000000000 4000000000000000 00
  let result153 = f64_add(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF0000000000000UL),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result153.value.to_bits(), 0x4000000000000000UL)
  @debug.assert_eq(result153.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f64_sub near_even after 1 4000000000000000 3FF0000000000000 3FF0000000000000 00
  let result154 = f64_sub(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x4000000000000000UL),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result154.value.to_bits(), 0x3FF0000000000000UL)
  @debug.assert_eq(result154.context.flags.to_bits(), 0x00U)
  // riscv f64_sub near_even after 1 4000000000000000 3FF0000000000000 3FF0000000000000 00
  let result155 = f64_sub(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x4000000000000000UL),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result155.value.to_bits(), 0x3FF0000000000000UL)
  @debug.assert_eq(result155.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f64_mul near_even after 1 3FF0000000000000 4000000000000000 4000000000000000 00
  let result156 = f64_mul(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF0000000000000UL),
    F64::from_bits(0x4000000000000000UL),
  )
  @debug.assert_eq(result156.value.to_bits(), 0x4000000000000000UL)
  @debug.assert_eq(result156.context.flags.to_bits(), 0x00U)
  // riscv f64_mul near_even after 1 3FF0000000000000 4000000000000000 4000000000000000 00
  let result157 = f64_mul(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF0000000000000UL),
    F64::from_bits(0x4000000000000000UL),
  )
  @debug.assert_eq(result157.value.to_bits(), 0x4000000000000000UL)
  @debug.assert_eq(result157.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f64_mul_add near_even after 1 4000000000000000 4008000000000000 3FF0000000000000 401C000000000000 00
  let result158 = f64_mul_add(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x4000000000000000UL),
    F64::from_bits(0x4008000000000000UL),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result158.value.to_bits(), 0x401C000000000000UL)
  @debug.assert_eq(result158.context.flags.to_bits(), 0x00U)
  // riscv f64_mul_add near_even after 1 4000000000000000 4008000000000000 3FF0000000000000 401C000000000000 00
  let result159 = f64_mul_add(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x4000000000000000UL),
    F64::from_bits(0x4008000000000000UL),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result159.value.to_bits(), 0x401C000000000000UL)
  @debug.assert_eq(result159.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f64_div near_even after 1 3FF0000000000000 4008000000000000 3FD5555555555555 01
  let result160 = f64_div(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF0000000000000UL),
    F64::from_bits(0x4008000000000000UL),
  )
  @debug.assert_eq(result160.value.to_bits(), 0x3FD5555555555555UL)
  @debug.assert_eq(result160.context.flags.to_bits(), 0x01U)
  // riscv f64_div near_even after 1 3FF0000000000000 4008000000000000 3FD5555555555555 01
  let result161 = f64_div(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF0000000000000UL),
    F64::from_bits(0x4008000000000000UL),
  )
  @debug.assert_eq(result161.value.to_bits(), 0x3FD5555555555555UL)
  @debug.assert_eq(result161.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f64_rem near_even after 1 4014000000000000 4000000000000000 3FF0000000000000 00
  let result162 = f64_rem(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x4014000000000000UL),
    F64::from_bits(0x4000000000000000UL),
  )
  @debug.assert_eq(result162.value.to_bits(), 0x3FF0000000000000UL)
  @debug.assert_eq(result162.context.flags.to_bits(), 0x00U)
  // riscv f64_rem near_even after 1 4014000000000000 4000000000000000 3FF0000000000000 00
  let result163 = f64_rem(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x4014000000000000UL),
    F64::from_bits(0x4000000000000000UL),
  )
  @debug.assert_eq(result163.value.to_bits(), 0x3FF0000000000000UL)
  @debug.assert_eq(result163.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f64_sqrt near_even after 1 4000000000000000 3FF6A09E667F3BCD 01
  let result164 = f64_sqrt(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x4000000000000000UL),
  )
  @debug.assert_eq(result164.value.to_bits(), 0x3FF6A09E667F3BCDUL)
  @debug.assert_eq(result164.context.flags.to_bits(), 0x01U)
  // riscv f64_sqrt near_even after 1 4000000000000000 3FF6A09E667F3BCD 01
  let result165 = f64_sqrt(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x4000000000000000UL),
  )
  @debug.assert_eq(result165.value.to_bits(), 0x3FF6A09E667F3BCDUL)
  @debug.assert_eq(result165.context.flags.to_bits(), 0x01U)
  // x86_8086_sse f64_eq near_even after 1 8000000000000000 0000000000000000 1 00
  let result166 = f64_eq(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x8000000000000000UL),
    F64::from_bits(0x0000000000000000UL),
  )
  @debug.assert_eq(result166.value, true)
  @debug.assert_eq(result166.context.flags.to_bits(), 0x00U)
  // riscv f64_eq near_even after 1 8000000000000000 0000000000000000 1 00
  let result167 = f64_eq(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x8000000000000000UL),
    F64::from_bits(0x0000000000000000UL),
  )
  @debug.assert_eq(result167.value, true)
  @debug.assert_eq(result167.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f64_le near_even after 1 3FF0000000000000 4000000000000000 1 00
  let result168 = f64_le(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF0000000000000UL),
    F64::from_bits(0x4000000000000000UL),
  )
  @debug.assert_eq(result168.value, true)
  @debug.assert_eq(result168.context.flags.to_bits(), 0x00U)
  // riscv f64_le near_even after 1 3FF0000000000000 4000000000000000 1 00
  let result169 = f64_le(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF0000000000000UL),
    F64::from_bits(0x4000000000000000UL),
  )
  @debug.assert_eq(result169.value, true)
  @debug.assert_eq(result169.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f64_lt near_even after 1 3FF0000000000000 4000000000000000 1 00
  let result170 = f64_lt(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF0000000000000UL),
    F64::from_bits(0x4000000000000000UL),
  )
  @debug.assert_eq(result170.value, true)
  @debug.assert_eq(result170.context.flags.to_bits(), 0x00U)
  // riscv f64_lt near_even after 1 3FF0000000000000 4000000000000000 1 00
  let result171 = f64_lt(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x3FF0000000000000UL),
    F64::from_bits(0x4000000000000000UL),
  )
  @debug.assert_eq(result171.value, true)
  @debug.assert_eq(result171.context.flags.to_bits(), 0x00U)
  // x86_8086_sse f64_eq_signaling near_even after 1 7FF8000000000000 3FF0000000000000 0 10
  let result172 = f64_eq_signaling(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x7FF8000000000000UL),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result172.value, false)
  @debug.assert_eq(result172.context.flags.to_bits(), 0x10U)
  // riscv f64_eq_signaling near_even after 1 7FF8000000000000 3FF0000000000000 0 10
  let result173 = f64_eq_signaling(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x7FF8000000000000UL),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result173.value, false)
  @debug.assert_eq(result173.context.flags.to_bits(), 0x10U)
  // x86_8086_sse f64_le_quiet near_even after 1 7FF0000000000001 3FF0000000000000 0 10
  let result174 = f64_le_quiet(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x7FF0000000000001UL),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result174.value, false)
  @debug.assert_eq(result174.context.flags.to_bits(), 0x10U)
  // riscv f64_le_quiet near_even after 1 7FF0000000000001 3FF0000000000000 0 10
  let result175 = f64_le_quiet(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x7FF0000000000001UL),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result175.value, false)
  @debug.assert_eq(result175.context.flags.to_bits(), 0x10U)
  // x86_8086_sse f64_lt_quiet near_even after 1 7FF0000000000001 3FF0000000000000 0 10
  let result176 = f64_lt_quiet(
    Context::default().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x7FF0000000000001UL),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result176.value, false)
  @debug.assert_eq(result176.context.flags.to_bits(), 0x10U)
  // riscv f64_lt_quiet near_even after 1 7FF0000000000001 3FF0000000000000 0 10
  let result177 = f64_lt_quiet(
    Context::riscv().with_rounding(NearEven).with_tininess(AfterRounding),
    F64::from_bits(0x7FF0000000000001UL),
    F64::from_bits(0x3FF0000000000000UL),
  )
  @debug.assert_eq(result177.value, false)
  @debug.assert_eq(result177.context.flags.to_bits(), 0x10U)
  // x86_8086_sse f64_is_signaling_nan near_even after 1 7FF0000000000001 1 00
  let result178 = f64_is_signaling_nan(F64::from_bits(0x7FF0000000000001UL))
  @debug.assert_eq(result178, true)
  @debug.assert_eq(0U, 0x00U)
  // riscv f64_is_signaling_nan near_even after 1 7FF0000000000001 1 00
  let result179 = f64_is_signaling_nan(F64::from_bits(0x7FF0000000000001UL))
  @debug.assert_eq(result179, true)
  @debug.assert_eq(0U, 0x00U)
}
