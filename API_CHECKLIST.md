# SoftFloat v1 API Checklist

This checklist maps the included `softfloat.h` Release 3e symbols to the v1
MoonBit API. MoonBit names use snake case: `roundToInt` becomes
`round_to_int`, `mulAdd` becomes `mul_add`, `isSignalingNaN` becomes
`is_signaling_nan`, and `_r_minMag` becomes `_min_mag`.

## Integer To Float

| SoftFloat symbol | MoonBit API |
| --- | --- |
| `ui32_to_f16` | `ui32_to_f16` |
| `ui32_to_f32` | `ui32_to_f32` |
| `ui32_to_f64` | `ui32_to_f64` |
| `ui64_to_f16` | `ui64_to_f16` |
| `ui64_to_f32` | `ui64_to_f32` |
| `ui64_to_f64` | `ui64_to_f64` |
| `i32_to_f16` | `i32_to_f16` |
| `i32_to_f32` | `i32_to_f32` |
| `i32_to_f64` | `i32_to_f64` |
| `i64_to_f16` | `i64_to_f16` |
| `i64_to_f32` | `i64_to_f32` |
| `i64_to_f64` | `i64_to_f64` |

## BF16

| SoftFloat symbol | MoonBit API |
| --- | --- |
| `bf16_to_f32` | `bf16_to_f32`, `BF16::to_f32` |
| `f32_to_bf16` | `f32_to_bf16`, `F32::to_bf16` |
| `bf16_isSignalingNaN` | `bf16_is_signaling_nan`, `BF16::is_signaling_nan` |

## F16

| SoftFloat symbol | MoonBit API |
| --- | --- |
| `f16_to_ui32` | `f16_to_ui32`, `F16::to_ui32` |
| `f16_to_ui64` | `f16_to_ui64`, `F16::to_ui64` |
| `f16_to_i32` | `f16_to_i32`, `F16::to_i32` |
| `f16_to_i64` | `f16_to_i64`, `F16::to_i64` |
| `f16_to_ui32_r_minMag` | `f16_to_ui32_min_mag`, `F16::to_ui32_min_mag` |
| `f16_to_ui64_r_minMag` | `f16_to_ui64_min_mag`, `F16::to_ui64_min_mag` |
| `f16_to_i32_r_minMag` | `f16_to_i32_min_mag`, `F16::to_i32_min_mag` |
| `f16_to_i64_r_minMag` | `f16_to_i64_min_mag`, `F16::to_i64_min_mag` |
| `f16_to_f32` | `f16_to_f32`, `F16::to_f32` |
| `f16_to_f64` | `f16_to_f64`, `F16::to_f64` |
| `f16_roundToInt` | `f16_round_to_int`, `F16::round_to_int` |
| `f16_add` | `f16_add`, `F16::add` |
| `f16_sub` | `f16_sub`, `F16::sub` |
| `f16_mul` | `f16_mul`, `F16::mul` |
| `f16_mulAdd` | `f16_mul_add`, `F16::mul_add` |
| `f16_div` | `f16_div`, `F16::div` |
| `f16_rem` | `f16_rem`, `F16::rem` |
| `f16_sqrt` | `f16_sqrt`, `F16::sqrt` |
| `f16_eq` | `f16_eq` |
| `f16_le` | `f16_le` |
| `f16_lt` | `f16_lt` |
| `f16_eq_signaling` | `f16_eq_signaling` |
| `f16_le_quiet` | `f16_le_quiet` |
| `f16_lt_quiet` | `f16_lt_quiet` |
| `f16_isSignalingNaN` | `f16_is_signaling_nan`, `F16::is_signaling_nan` |

## F32

| SoftFloat symbol | MoonBit API |
| --- | --- |
| `f32_to_ui32` | `f32_to_ui32`, `F32::to_ui32` |
| `f32_to_ui64` | `f32_to_ui64`, `F32::to_ui64` |
| `f32_to_i32` | `f32_to_i32`, `F32::to_i32` |
| `f32_to_i64` | `f32_to_i64`, `F32::to_i64` |
| `f32_to_ui32_r_minMag` | `f32_to_ui32_min_mag`, `F32::to_ui32_min_mag` |
| `f32_to_ui64_r_minMag` | `f32_to_ui64_min_mag`, `F32::to_ui64_min_mag` |
| `f32_to_i32_r_minMag` | `f32_to_i32_min_mag`, `F32::to_i32_min_mag` |
| `f32_to_i64_r_minMag` | `f32_to_i64_min_mag`, `F32::to_i64_min_mag` |
| `f32_to_bf16` | `f32_to_bf16`, `F32::to_bf16` |
| `f32_to_f16` | `f32_to_f16`, `F32::to_f16` |
| `f32_to_f64` | `f32_to_f64`, `F32::to_f64` |
| `f32_roundToInt` | `f32_round_to_int`, `F32::round_to_int` |
| `f32_add` | `f32_add`, `F32::add` |
| `f32_sub` | `f32_sub`, `F32::sub` |
| `f32_mul` | `f32_mul`, `F32::mul` |
| `f32_mulAdd` | `f32_mul_add`, `F32::mul_add` |
| `f32_div` | `f32_div`, `F32::div` |
| `f32_rem` | `f32_rem`, `F32::rem` |
| `f32_sqrt` | `f32_sqrt`, `F32::sqrt` |
| `f32_eq` | `f32_eq` |
| `f32_le` | `f32_le` |
| `f32_lt` | `f32_lt` |
| `f32_eq_signaling` | `f32_eq_signaling` |
| `f32_le_quiet` | `f32_le_quiet` |
| `f32_lt_quiet` | `f32_lt_quiet` |
| `f32_isSignalingNaN` | `f32_is_signaling_nan`, `F32::is_signaling_nan` |

## F64

| SoftFloat symbol | MoonBit API |
| --- | --- |
| `f64_to_ui32` | `f64_to_ui32`, `F64::to_ui32` |
| `f64_to_ui64` | `f64_to_ui64`, `F64::to_ui64` |
| `f64_to_i32` | `f64_to_i32`, `F64::to_i32` |
| `f64_to_i64` | `f64_to_i64`, `F64::to_i64` |
| `f64_to_ui32_r_minMag` | `f64_to_ui32_min_mag`, `F64::to_ui32_min_mag` |
| `f64_to_ui64_r_minMag` | `f64_to_ui64_min_mag`, `F64::to_ui64_min_mag` |
| `f64_to_i32_r_minMag` | `f64_to_i32_min_mag`, `F64::to_i32_min_mag` |
| `f64_to_i64_r_minMag` | `f64_to_i64_min_mag`, `F64::to_i64_min_mag` |
| `f64_to_f16` | `f64_to_f16`, `F64::to_f16` |
| `f64_to_f32` | `f64_to_f32`, `F64::to_f32` |
| `f64_roundToInt` | `f64_round_to_int`, `F64::round_to_int` |
| `f64_add` | `f64_add`, `F64::add` |
| `f64_sub` | `f64_sub`, `F64::sub` |
| `f64_mul` | `f64_mul`, `F64::mul` |
| `f64_mulAdd` | `f64_mul_add`, `F64::mul_add` |
| `f64_div` | `f64_div`, `F64::div` |
| `f64_rem` | `f64_rem`, `F64::rem` |
| `f64_sqrt` | `f64_sqrt`, `F64::sqrt` |
| `f64_eq` | `f64_eq` |
| `f64_le` | `f64_le` |
| `f64_lt` | `f64_lt` |
| `f64_eq_signaling` | `f64_eq_signaling` |
| `f64_le_quiet` | `f64_le_quiet` |
| `f64_lt_quiet` | `f64_lt_quiet` |
| `f64_isSignalingNaN` | `f64_is_signaling_nan`, `F64::is_signaling_nan` |

## Constructors And Context

| Requirement | MoonBit API |
| --- | --- |
| F16/BF16/F32/F64 bit wrappers | `F16`, `BF16`, `F32`, `F64` |
| Bit constructors/accessors | `from_bits`, `to_bits` methods |
| Host bit reinterpretation | `F32::from_float_bits`, `F32::to_float_bits`, `F64::from_double_bits`, `F64::to_double_bits` |
| Explicit SoftFloat state | `Context` |
| Default 8086-SSE profile | `Context::default()` |
| RISCV profile | `Context::riscv()` |
| Context updates | `with_rounding`, `with_tininess`, `with_specialization`, `clear_flags`, `raise_flags` |
| Exception flag inspection | `ExceptionFlags::contains`, `ExceptionFlags::to_bits` |

`Context::raise_flags` is the MoonBit spelling for the planned
`Context::raise`, because `raise` is a MoonBit keyword.

## Excluded From V1

The following `softfloat.h` families are intentionally excluded and have no
MoonBit public API in v1:

- `extF80`, `extF80M`, `f128`, and `f128M` formats.
- All conversions to or from excluded formats.
- All `*M` memory-form APIs.
- `extF80_roundingPrecision` and operations depending on it.
- Non-`SOFTFLOAT_FAST_INT64` fallback paths.
- Global mutable SoftFloat state; v1 uses explicit `Context` threading.

## Oracle Evidence

- `tools/vectors/core.txt` contains generated C oracle records for every
  v1 function-style operation across both `x86_8086_sse` and `riscv`.
- `golden_core_wbtest.mbt` checks MoonBit results and exception flags against
  those committed records.
- `tools/test_gen.mjs sweep` generates operation/specialization
  split edge, random, and F16 exhaustive fixtures with seed `0x5F0F7A7C`.
- `golden_sweep_digest_wbtest.mbt` checks MoonBit results and exception flags
  for those sweep inputs by comparing per-file digests against the C-oracle
  records.
- `tools/check_vectors.sh` replays all committed text fixtures in batch
  against the local C oracle binaries.
