# MoonBit SoftFloat v1 Development Plan

## Source Baseline

- Upstream source: `berkeley-softfloat-3` at commit `a0c6494`, Berkeley SoftFloat Release 3e.
- Reference headers:
  - `berkeley-softfloat-3/source/include/softfloat_types.h`
  - `berkeley-softfloat-3/source/include/softfloat.h`
  - `berkeley-softfloat-3/source/include/internals.h`
  - `berkeley-softfloat-3/source/include/primitives.h`
- Reference build profiles:
  - `berkeley-softfloat-3/build/Linux-x86_64-GCC/Makefile`: `SPECIALIZE_TYPE=8086-SSE`, `SOFTFLOAT_FAST_INT64`, `SOFTFLOAT_ROUND_ODD`.
  - `berkeley-softfloat-3/build/Linux-RISCV64-GCC/Makefile`: `SPECIALIZE_TYPE=RISCV`, `SOFTFLOAT_FAST_INT64`, `SOFTFLOAT_ROUND_ODD`.
- v1 must be a pure MoonBit implementation. C SoftFloat is used only as a local golden-vector oracle.

## Scope

### Included Public Formats

- `F16`: IEEE 754 binary16, stored as `UInt16`.
- `BF16`: bfloat16, stored as `UInt16`.
- `F32`: IEEE 754 binary32, stored as `UInt`.
- `F64`: IEEE 754 binary64, stored as `UInt64`.

### Included SoftFloat Operations

Integer-to-float conversions:

- `ui32_to_f16`, `ui32_to_f32`, `ui32_to_f64`
- `ui64_to_f16`, `ui64_to_f32`, `ui64_to_f64`
- `i32_to_f16`, `i32_to_f32`, `i32_to_f64`
- `i64_to_f16`, `i64_to_f32`, `i64_to_f64`

`F16` operations:

- Integer conversions: `f16_to_ui32`, `f16_to_ui64`, `f16_to_i32`, `f16_to_i64`
- MinMag integer conversions: `f16_to_ui32_r_minMag`, `f16_to_ui64_r_minMag`, `f16_to_i32_r_minMag`, `f16_to_i64_r_minMag`
- Float conversions: `f16_to_f32`, `f16_to_f64`
- Arithmetic: `f16_roundToInt`, `f16_add`, `f16_sub`, `f16_mul`, `f16_mulAdd`, `f16_div`, `f16_rem`, `f16_sqrt`
- Comparisons: `f16_eq`, `f16_le`, `f16_lt`, `f16_eq_signaling`, `f16_le_quiet`, `f16_lt_quiet`
- NaN predicate: `f16_isSignalingNaN`

`BF16` operations:

- `bf16_to_f32`
- `f32_to_bf16`
- `bf16_isSignalingNaN`
- No standalone BF16 arithmetic in v1 because SoftFloat Release 3e exposes none.

`F32` operations:

- Integer conversions: `f32_to_ui32`, `f32_to_ui64`, `f32_to_i32`, `f32_to_i64`
- MinMag integer conversions: `f32_to_ui32_r_minMag`, `f32_to_ui64_r_minMag`, `f32_to_i32_r_minMag`, `f32_to_i64_r_minMag`
- Float conversions: `f32_to_bf16`, `f32_to_f16`, `f32_to_f64`
- Arithmetic: `f32_roundToInt`, `f32_add`, `f32_sub`, `f32_mul`, `f32_mulAdd`, `f32_div`, `f32_rem`, `f32_sqrt`
- Comparisons: `f32_eq`, `f32_le`, `f32_lt`, `f32_eq_signaling`, `f32_le_quiet`, `f32_lt_quiet`
- NaN predicate: `f32_isSignalingNaN`

`F64` operations:

- Integer conversions: `f64_to_ui32`, `f64_to_ui64`, `f64_to_i32`, `f64_to_i64`
- MinMag integer conversions: `f64_to_ui32_r_minMag`, `f64_to_ui64_r_minMag`, `f64_to_i32_r_minMag`, `f64_to_i64_r_minMag`
- Float conversions: `f64_to_f16`, `f64_to_f32`
- Arithmetic: `f64_roundToInt`, `f64_add`, `f64_sub`, `f64_mul`, `f64_mulAdd`, `f64_div`, `f64_rem`, `f64_sqrt`
- Comparisons: `f64_eq`, `f64_le`, `f64_lt`, `f64_eq_signaling`, `f64_le_quiet`, `f64_lt_quiet`
- NaN predicate: `f64_isSignalingNaN`

### Excluded From v1

- `extF80`, `extF80M`, `f128`, `f128M`, and all conversions to or from them.
- `*M` memory-form APIs.
- The non-`SOFTFLOAT_FAST_INT64` paths and their array-based fallback helpers, except small typed helpers needed to express `f64_mulAdd`.
- Global mutable SoftFloat state. MoonBit must pass and return explicit context.
- Any dependency on host floating-point arithmetic for SoftFloat results. Native bridges are bit reinterpretation helpers only.

## Public MoonBit API

The API should preserve SoftFloat semantics while using MoonBit naming and explicit context.

Core types:

- Opaque wrappers:
  - `F16(UInt16)`
  - `BF16(UInt16)`
  - `F32(UInt)`
  - `F64(UInt64)`
- `Context { rounding: RoundingMode, tininess: TininessMode, flags: ExceptionFlags, specialization: Specialization }`
- `SoftResult[T] { value: T, context: Context }`
- `RoundingMode`: `NearEven`, `MinMag`, `Min`, `Max`, `NearMaxMag`, `Odd`
- `TininessMode`: `BeforeRounding`, `AfterRounding`
- `ExceptionFlags`: bit wrapper with `Inexact=1`, `Underflow=2`, `Overflow=4`, `Infinite=8`, `Invalid=16`
- `Specialization`: `X86_8086SSE`, `RISCV`

Required constructors and bit accessors:

- `F16::from_bits(bits: UInt16) -> F16`
- `F16::to_bits(self) -> UInt16`
- `BF16::from_bits(bits: UInt16) -> BF16`
- `BF16::to_bits(self) -> UInt16`
- `F32::from_bits(bits: UInt) -> F32`
- `F32::to_bits(self) -> UInt`
- `F64::from_bits(bits: UInt64) -> F64`
- `F64::to_bits(self) -> UInt64`
- `F32::from_float_bits(value: Float) -> F32`
- `F32::to_float_bits(self) -> Float`
- `F64::from_double_bits(value: Double) -> F64`
- `F64::to_double_bits(self) -> Double`

Required context helpers:

- `Context::default() -> Context`: `NearEven`, `AfterRounding`, empty flags, `X86_8086SSE`.
- `Context::riscv() -> Context`: `NearEven`, `AfterRounding`, empty flags, `RISCV`.
- `Context::with_rounding(self, rounding: RoundingMode) -> Context`
- `Context::with_tininess(self, tininess: TininessMode) -> Context`
- `Context::with_specialization(self, specialization: Specialization) -> Context`
- `Context::clear_flags(self) -> Context`
- `Context::raise(self, flags: ExceptionFlags) -> Context`
- `ExceptionFlags::contains(self, flag: ExceptionFlags) -> Bool`

Operation API shape:

- Every operation that can set exception flags returns `SoftResult[T]`.
- NaN predicate methods return `Bool` because they do not raise flags.
- Comparison methods return `SoftResult[Bool]` because comparisons can raise `Invalid`.
- Integer-to-float conversions return `SoftResult[F16]`, `SoftResult[F32]`, or `SoftResult[F64]` because they can raise `Inexact`.
- Float-to-integer conversions return `SoftResult[UInt]`, `SoftResult[UInt64]`, `SoftResult[Int]`, or `SoftResult[Int64]`.
- `round_to_int` accepts an operation-local `RoundingMode` and `exact: Bool`, matching SoftFloat.
- Float-to-integer conversions accept an operation-local `RoundingMode` and `exact: Bool`, matching SoftFloat.

## MoonBit Package Layout

Create one root package first, then split later only if the public API grows too large.

- `moon.pkg`: root library package.
- `types.mbt`: opaque wrappers, `SoftResult`, small tuple/result structs.
- `context.mbt`: rounding/tininess/flags/specialization and context helpers.
- `bits.mbt`: sign/exp/fraction extractors, packers, NaN field predicates for F16/BF16/F32/F64.
- `uint128.mbt`: typed `UInt128`, `UInt64Extra`, add/sub/compare/mul/shift helpers.
- `primitive_shift.mbt`: jam shifts and leading-zero helpers.
- `primitive_approx.mbt`: reciprocal and reciprocal-sqrt tables/functions.
- `specialize.mbt`: specialization table and NaN propagation/common-NaN conversions.
- `round_int.mbt`: `roundToUI32`, `roundToUI64`, `roundToI32`, `roundToI64`.
- `round_pack.mbt`: `roundPackToBF16/F16/F32/F64`, `normRoundPackToF16/F32/F64`.
- `f16_ops.mbt`: all F16 operations and conversions out of F16.
- `bf16_ops.mbt`: BF16 operations and F32-to-BF16 conversion.
- `f32_ops.mbt`: all F32 operations and conversions out of F32 except BF16 if kept in `bf16_ops.mbt`.
- `f64_ops.mbt`: all F64 operations and conversions out of F64.
- `int_to_float.mbt`: signed/unsigned integer-to-F16/F32/F64 conversions.
- `*_test.mbt`: focused tests in the same package.
- `pkg.generated.mbti`: generated by `moon info` and committed after the first stable API pass.

MoonBit file organization rules:

- Use `///|` top-level delimiters.
- Keep files cohesive; do not create a generic `utils.mbt`.
- File names are organizational only; do not model them as namespaces.

## Documentation Requirements

Every implementation stage must pair code changes with appropriate documentation before the stage is considered complete.

- Public types, constructors, methods, and functions must include concise MoonBit API documentation that states the SoftFloat behavior, context and flag effects, rounding/tininess inputs, and any specialization-dependent NaN or invalid-result behavior.
- Public examples belong in `README.mbt.md` when they can be checked as MoonBit Markdown tests; otherwise keep user-facing usage notes in `README.md`.
- Internal helpers that directly port non-obvious SoftFloat primitives must name the upstream C source file or algorithm in a short comment near the implementation.
- Any new fixture, oracle, or generation tool must update `tools/golden/README.md` with input/output format, regeneration command, random seed, and specialization coverage.
- Any public API addition, exclusion, or semantic constraint must be reflected in the README or the Stage 7 API checklist, so users can tell what v1 supports without reading source.
- Generated `pkg.generated.mbti` changes must be reviewed together with the related API docs before handoff.

## Internal Porting Plan

### Stage 0: Project Skeleton

Tasks:

- Add `moon.pkg`.
- Add empty public types and context helpers.
- Add a short README section that says the implementation is pure MoonBit and SoftFloat C is used only as a local golden-vector oracle.

Acceptance:

- `moon check`
- `moon fmt`
- `moon info`
- Initial README documentation is present.

### Stage 1: Bit Types, Context, and Specialization

Source references:

- `softfloat_types.h`
- `softfloat.h`
- `internals.h`
- `source/8086-SSE/specialize.h`
- `source/RISCV/specialize.h`
- `source/8086-SSE/s_*NaN*.c`
- `source/RISCV/s_*NaN*.c`

Tasks:

- Implement exact bit wrappers and `from_bits` / `to_bits`.
- Implement `RoundingMode` numeric mapping: `NearEven=0`, `MinMag=1`, `Min=2`, `Max=3`, `NearMaxMag=4`, `Odd=6`.
- Implement `TininessMode` numeric mapping: `BeforeRounding=0`, `AfterRounding=1`.
- Implement exception flag accumulation with no global state.
- Implement field helpers:
  - F16: `signF16UI`, `expF16UI`, `fracF16UI`, `packToF16UI`, `isNaNF16UI`
  - BF16: `signBF16UI`, `expBF16UI`, `fracBF16UI`, `packToBF16UI`, `isNaNBF16UI`
  - F32: `signF32UI`, `expF32UI`, `fracF32UI`, `packToF32UI`, `isNaNF32UI`
  - F64: `signF64UI`, `expF64UI`, `fracF64UI`, `packToF64UI`, `isNaNF64UI`
- Implement specialization constants:
  - `X86_8086SSE`: F16 `0xFE00`, F32 `0xFFC00000`, F64 `0xFFF8000000000000`; integer invalid returns match `8086-SSE/specialize.h`.
  - `RISCV`: F16 `0x7E00`, BF16 `0x7FC0`, F32 `0x7FC00000`, F64 `0x7FF8000000000000`; integer invalid returns match `RISCV/specialize.h`.
- Implement signaling-NaN predicates for F16/BF16/F32/F64.
- Implement common-NaN conversion and propagation:
  - X86 preserves sign/payload where `8086-SSE` does.
  - RISCV returns canonical default NaNs and raises `Invalid` for sNaN.

Acceptance:

- Unit tests for all pack/unpack helpers.
- Unit tests for sNaN/qNaN classification at boundary payloads.
- Unit tests for X86 vs RISCV default-NaN and integer invalid constants.
- `moon check`

### Stage 2: Primitive Integer Helpers

Source references:

- `primitiveTypes.h`
- `primitives.h`
- `s_countLeadingZeros8.c`
- `s_countLeadingZeros16.c`
- `s_countLeadingZeros32.c`
- `s_countLeadingZeros64.c`
- `s_shiftRightJam32.c`
- `s_shiftRightJam64.c`
- `s_shiftRightJam64Extra.c`
- `s_shortShiftRightJam64.c`
- `s_shortShiftRightJam128.c`
- `s_shiftRightJam128.c`
- `s_shortShiftLeft128.c`
- `s_shortShiftRight128.c`
- `s_add128.c`
- `s_sub128.c`
- `s_mul64To128.c`
- `s_approxRecip_1Ks.c`
- `s_approxRecip32_1.c`
- `s_approxRecipSqrt_1Ks.c`
- `s_approxRecipSqrt32_1.c`

Tasks:

- Implement `UInt128 { hi: UInt64, lo: UInt64 }`.
- Implement `UInt64Extra { value: UInt64, extra: UInt64 }`.
- Implement leading-zero counts for 8/16/32/64.
- Implement jam shifts for 32/64/128 and 64-extra.
- Implement 128-bit compare/add/sub/short shifts.
- Implement `mul64To128`.
- Implement reciprocal and reciprocal-sqrt approximation tables.
- For `f64_mulAdd`, implement typed equivalents of C macros:
  - `add128M`
  - `sub128M`
  - `negX128M`
  - `shiftLeft128M`
  - `shortShiftRight128M`
  - `shiftRightJam128M`

Acceptance:

- Unit tests for all boundary shift distances: 0, 1, word size minus 1, word size, word size plus 1, and larger than total width.
- Unit tests for carry, borrow, compare, and `mul64To128`.
- Cross-check reciprocal tables against C table constants.
- `moon check`

### Stage 3: Rounding and Packing

Source references:

- `s_roundToUI32.c`
- `s_roundToUI64.c`
- `s_roundToI32.c`
- `s_roundToI64.c`
- `s_roundPackToBF16.c`
- `s_roundPackToF16.c`
- `s_roundPackToF32.c`
- `s_roundPackToF64.c`
- `s_normSubnormalBF16Sig.c`
- `s_normSubnormalF16Sig.c`
- `s_normSubnormalF32Sig.c`
- `s_normSubnormalF64Sig.c`
- `s_normRoundPackToF16.c`
- `s_normRoundPackToF32.c`
- `s_normRoundPackToF64.c`

Tasks:

- Port integer rounding helpers with context threading.
- Port BF16/F16/F32/F64 round-pack helpers with context threading.
- Preserve `SOFTFLOAT_ROUND_ODD` behavior.
- Preserve tininess-before vs tininess-after behavior.
- Use specialization-specific overflow return constants for float-to-integer invalid cases.

Acceptance:

- Unit tests for all rounding modes.
- Unit tests for exact vs inexact flag behavior.
- Unit tests for overflow, underflow, invalid, infinite, and signed-zero output.
- Golden vector checks for round-pack and integer rounding helper edge cases.
- `moon check`

### Stage 4: F16 and BF16

Source files:

- `bf16_isSignalingNaN.c`
- `bf16_to_f32.c`
- `f32_to_bf16.c`
- `f16_to_ui32.c`
- `f16_to_ui64.c`
- `f16_to_i32.c`
- `f16_to_i64.c`
- `f16_to_ui32_r_minMag.c`
- `f16_to_ui64_r_minMag.c`
- `f16_to_i32_r_minMag.c`
- `f16_to_i64_r_minMag.c`
- `f16_to_f32.c`
- `f16_to_f64.c`
- `f16_roundToInt.c`
- `f16_add.c`
- `f16_sub.c`
- `f16_mul.c`
- `f16_mulAdd.c`
- `f16_div.c`
- `f16_rem.c`
- `f16_sqrt.c`
- `f16_eq.c`
- `f16_le.c`
- `f16_lt.c`
- `f16_eq_signaling.c`
- `f16_le_quiet.c`
- `f16_lt_quiet.c`
- `f16_isSignalingNaN.c`
- Internal helpers: `s_addMagsF16.c`, `s_subMagsF16.c`, `s_mulAddF16.c`

Tasks:

- Implement BF16 predicate/conversion first because it is small and validates specialization hooks.
- Implement F16 conversions before arithmetic.
- Implement F16 arithmetic in this order: add/sub, mul, mulAdd, div, rem, sqrt, roundToInt.
- Implement comparisons after NaN behavior is verified.

Acceptance:

- Exhaustive F16 unary tests where practical: all 65,536 inputs for classification, F16-to-F32/F64, roundToInt selected modes, and scalar edge cases.
- Pairwise F16 arithmetic tests use fixed edge-set cross product plus random vectors.
- BF16 tests include all NaN payload classes and fixed random F32-to-BF16 vectors.
- Compare results and flags against both X86 and RISCV C oracles.
- `moon check`
- `moon test`

### Stage 5: F32

Source files:

- `ui32_to_f32.c`, `ui64_to_f32.c`, `i32_to_f32.c`, `i64_to_f32.c`
- `f32_to_ui32.c`, `f32_to_ui64.c`, `f32_to_i32.c`, `f32_to_i64.c`
- `f32_to_ui32_r_minMag.c`, `f32_to_ui64_r_minMag.c`, `f32_to_i32_r_minMag.c`, `f32_to_i64_r_minMag.c`
- `f32_to_f16.c`, `f32_to_f64.c`
- `f32_roundToInt.c`
- `f32_add.c`, `f32_sub.c`, `f32_mul.c`, `f32_mulAdd.c`, `f32_div.c`, `f32_rem.c`, `f32_sqrt.c`
- `f32_eq.c`, `f32_le.c`, `f32_lt.c`, `f32_eq_signaling.c`, `f32_le_quiet.c`, `f32_lt_quiet.c`, `f32_isSignalingNaN.c`
- Internal helpers: `s_addMagsF32.c`, `s_subMagsF32.c`, `s_mulAddF32.c`

Tasks:

- Implement integer-to-F32 conversions.
- Implement F32-to-integer conversions and MinMag variants.
- Implement F32-to-F16/F64 conversions.
- Implement F32 arithmetic in this order: add/sub, mul, mulAdd, div, rem, sqrt, roundToInt.
- Implement comparisons.

Acceptance:

- Edge-set cross product for all binary operations.
- Random vectors per operation with fixed seed.
- Dedicated tests for subnormal normalization, halfway rounding, signed zero, division by zero, infinity arithmetic, qNaN/sNaN propagation, and FMA cancellation.
- Compare results and flags against both C oracles.
- `moon check`
- `moon test`

### Stage 6: F64

Source files:

- `ui32_to_f64.c`, `ui64_to_f64.c`, `i32_to_f64.c`, `i64_to_f64.c`
- `f64_to_ui32.c`, `f64_to_ui64.c`, `f64_to_i32.c`, `f64_to_i64.c`
- `f64_to_ui32_r_minMag.c`, `f64_to_ui64_r_minMag.c`, `f64_to_i32_r_minMag.c`, `f64_to_i64_r_minMag.c`
- `f64_to_f16.c`, `f64_to_f32.c`
- `f64_roundToInt.c`
- `f64_add.c`, `f64_sub.c`, `f64_mul.c`, `f64_mulAdd.c`, `f64_div.c`, `f64_rem.c`, `f64_sqrt.c`
- `f64_eq.c`, `f64_le.c`, `f64_lt.c`, `f64_eq_signaling.c`, `f64_le_quiet.c`, `f64_lt_quiet.c`, `f64_isSignalingNaN.c`
- Internal helpers: `s_addMagsF64.c`, `s_subMagsF64.c`, `s_mulAddF64.c`

Tasks:

- Implement integer-to-F64 conversions.
- Implement F64-to-integer conversions and MinMag variants.
- Implement F64-to-F16/F32 conversions.
- Implement F64 arithmetic in this order: add/sub, mul, mulAdd, div, rem, sqrt, roundToInt.
- Pay special attention to `f64_mulAdd`: it uses 128-bit intermediate helpers and typed equivalents of C array macros.
- Implement comparisons.

Acceptance:

- Edge-set cross product for all binary operations.
- Random vectors per operation with fixed seed.
- Dedicated tests for 64-bit integer conversion overflow, high-precision rounding boundaries, FMA cancellation, and sqrt/rem corner cases.
- Compare results and flags against both C oracles.
- `moon check`
- `moon test`

### Stage 7: Cross-Format and Full API Audit

Tasks:

- Verify every included `softfloat.h` function has a MoonBit API equivalent.
- Verify every excluded function is documented as excluded.
- Generate `pkg.generated.mbti` with `moon info`.
- Review public names for consistency before freezing v1.

Acceptance:

- A checklist mapping every included C symbol to a MoonBit function/method.
- No accidental public helpers in `pkg.generated.mbti`.
- `moon check`
- `moon test`
- `moon fmt`
- `moon info`

## Golden Oracle Plan

Create local test-oracle tooling under `tools/golden/`.

Files:

- `tools/golden/oracle.c`: CLI that links against local SoftFloat sources.
- `tools/golden/build.sh`: builds two oracle binaries:
  - `tools/golden/oracle-8086-sse`
  - `tools/golden/oracle-riscv`
- `tools/golden/vectors/`: generated fixtures committed to the repository.
- `tools/golden/README.md`: documents fixture format and regeneration commands.

Oracle build rules:

- For X86 oracle:
  - Include path: `berkeley-softfloat-3/source/8086-SSE`
  - Defines: `SOFTFLOAT_FAST_INT64`, `SOFTFLOAT_ROUND_ODD`
- For RISCV oracle:
  - Include path: `berkeley-softfloat-3/source/RISCV`
  - Defines: `SOFTFLOAT_FAST_INT64`, `SOFTFLOAT_ROUND_ODD`
- Use host `gcc` for both oracles. The RISCV oracle means RISCV SoftFloat specialization, not a RISC-V target binary.
- Use `berkeley-softfloat-3/build/Linux-x86_64-GCC/platform.h` for host platform macros.
- Compile all generic `berkeley-softfloat-3/source/*.c` files and all files from the selected specialization directory into each oracle binary. The wrapper CLI must expose only v1 operations listed in this plan.

Fixture format:

- Use line-oriented text so MoonBit tests can parse it simply.
- Fields:
  - `specialization`
  - `operation`
  - `rounding`
  - `tininess`
  - `exact`
  - `input_bits`
  - `output_bits_or_integer`
  - `flags`
- All bit patterns are hex strings with fixed width.

Vector strategy:

- Edge values for each format:
  - positive and negative zero
  - minimum and maximum subnormals
  - minimum and maximum normals
  - one, minus one, two, one half
  - maximum finite
  - positive and negative infinity
  - quiet NaNs with multiple payloads
  - signaling NaNs with multiple payloads
- Rounding modes:
  - Test all six modes for round-to-int, integer conversions, round-pack paths, and conversions where rounding matters.
  - For arithmetic, run at least `NearEven`, `Min`, `Max`, and `Odd` in golden sweeps.
- Tininess modes:
  - Test both `BeforeRounding` and `AfterRounding` for underflow-sensitive operations.
- Random vectors:
  - Fixed seed: `0x5F0F7A7C`.
  - Minimum per binary operation: 10,000 F32 vectors and 10,000 F64 vectors.
  - Minimum per ternary FMA operation: 10,000 vectors.
  - Minimum per F16 binary operation: 65,536 sampled pairs plus targeted exhaustive unary tests.
  - Store random fixtures by operation and specialization, not one giant file.

## Validation Commands

Run after each implementation stage:

- `moon check`
- `moon test`
- `moon fmt`
- Review and update the relevant README/API/tooling documentation for all code written in the stage.

Run before handoff or PR:

- `moon check --warn-list +73`
- `moon test`
- `moon fmt`
- `moon info`
- `git diff --check`
- Confirm documentation matches the final public API and generated fixtures.

## Completion Criteria

v1 is complete only when:

- Every included SoftFloat symbol listed in this plan has a MoonBit equivalent.
- All results and exception flags match local C SoftFloat for both `8086-SSE` and `RISCV` specializations over committed fixtures.
- Default `Context` matches `Linux-x86_64-GCC` / `8086-SSE`.
- No global mutable state is used for rounding mode, tininess mode, exception flags, or specialization.
- `pkg.generated.mbti` exposes only the intended public API.
- Public APIs, examples, oracle tooling, fixture formats, and exclusions have matching documentation.
