///|
/// SoftFloat rounding modes.
///
/// `NearEven` rounds to the nearest representable value and breaks exact
/// half-way ties toward an even low bit. `NearMaxMag` also rounds to nearest
/// but breaks half-way ties away from zero. `MinMag` truncates toward zero,
/// `Min` rounds toward negative infinity, `Max` rounds toward positive
/// infinity, and `Odd` uses the SoftFloat round-to-odd rule: after truncating,
/// any inexact result is forced to have an odd least significant bit.
///
/// Numeric mappings follow `softfloat.h`: NearEven=0, MinMag=1, Min=2,
/// Max=3, NearMaxMag=4, and Odd=6. The gap at code 5 is intentional.
pub(all) enum RoundingMode {
  NearEven
  MinMag
  Min
  Max
  NearMaxMag
  Odd
} derive(Eq)

///|
/// SoftFloat underflow tininess detection mode.
///
/// This setting only controls when an operation raises the `Underflow` flag;
/// it does not change the mathematical operation being requested. In
/// `BeforeRounding` mode, tininess may be reported before final rounding can
/// rescue a result into the normal range. In `AfterRounding` mode, tininess is
/// tested on the rounded result, matching the default context.
///
/// Numeric mappings follow `softfloat.h`: BeforeRounding=0 and
/// AfterRounding=1.
pub(all) enum TininessMode {
  BeforeRounding
  AfterRounding
} derive(Eq)

///|
/// SoftFloat specialization profile.
///
/// v1 models the Release 3e 8086-SSE and RISCV profiles. The profile controls
/// default NaN bit patterns, NaN payload propagation, and the integer value
/// returned when a float-to-integer conversion raises `Invalid`. It does not
/// change the public function signatures or make flags global.
pub(all) enum Specialization {
  X86_8086SSE
  RISCV
} derive(Eq)

///|
/// Accumulated IEEE exception flags.
///
/// Bits match SoftFloat: Inexact=1, Underflow=2, Overflow=4, Infinite=8,
/// Invalid=16. Flags are immutable and accumulated through
/// `Context::raise_flags`; operations preserve any flags already present in
/// the input context and OR in newly raised flags. Use `from_bits` when
/// importing raw flag bits; it masks off bits outside the SoftFloat range.
pub struct ExceptionFlags(UInt)

///|
/// Returns an empty exception-flag set.
///
/// This value has raw bits `0` and is contained by every flag set when passed
/// to `ExceptionFlags::contains`.
pub fn ExceptionFlags::empty() -> ExceptionFlags {
  ExceptionFlags(0U)
}

///|
/// Returns the raw SoftFloat exception flag bits.
///
/// Only the low five bits are used by this package.
pub fn ExceptionFlags::to_bits(self : ExceptionFlags) -> UInt {
  self.0
}

///|
/// Creates exception flags from raw SoftFloat flag bits.
///
/// Bits outside the SoftFloat exception mask are discarded, so
/// `ExceptionFlags::from_bits(bits).to_bits()` is always in `0x00..0x1f`.
pub fn ExceptionFlags::from_bits(bits : UInt) -> ExceptionFlags {
  ExceptionFlags(bits & 0x1FU)
}

///|
/// SoftFloat inexact flag.
///
/// Raised when a finite result had to be rounded or when an exact-conversion
/// request loses nonzero bits.
pub fn ExceptionFlags::inexact() -> ExceptionFlags {
  ExceptionFlags(1U)
}

///|
/// SoftFloat underflow flag.
///
/// Raised for tiny inexact floating results according to the context's
/// tininess mode.
pub fn ExceptionFlags::underflow() -> ExceptionFlags {
  ExceptionFlags(2U)
}

///|
/// SoftFloat overflow flag.
///
/// Raised when a finite floating result is too large for the destination
/// format. Overflow is paired with `Inexact` by the rounding helpers.
pub fn ExceptionFlags::overflow() -> ExceptionFlags {
  ExceptionFlags(4U)
}

///|
/// SoftFloat infinite flag.
///
/// Raised for finite nonzero division by zero, producing a signed infinity.
pub fn ExceptionFlags::infinite() -> ExceptionFlags {
  ExceptionFlags(8U)
}

///|
/// SoftFloat invalid flag.
///
/// Raised for operations such as signaling-NaN consumption, invalid infinity
/// arithmetic, square root of a negative nonzero value, and invalid
/// float-to-integer conversions.
pub fn ExceptionFlags::invalid() -> ExceptionFlags {
  ExceptionFlags(16U)
}

///|
/// Returns true when all bits in `flag` are present in this flag set.
///
/// Passing `ExceptionFlags::empty()` returns true. Passing a multi-bit flag set
/// only returns true when every requested bit is present.
pub fn ExceptionFlags::contains(
  self : ExceptionFlags,
  flag : ExceptionFlags,
) -> Bool {
  (self.0 & flag.0) == flag.0
}

///|
/// Returns a flag set with `other` accumulated.
///
/// This is a bitwise OR operation. It never clears existing flags and merging
/// the same flag repeatedly is idempotent.
pub fn ExceptionFlags::merge(
  self : ExceptionFlags,
  other : ExceptionFlags,
) -> ExceptionFlags {
  ExceptionFlags(self.0 | other.0)
}

///|
/// Explicit SoftFloat execution context.
///
/// The context replaces SoftFloat's global mutable rounding mode, tininess
/// mode, exception flags, and specialization profile. Public operations return
/// a `SoftResult` with an updated context; the input context value is not
/// mutated. Existing flags are preserved until `Context::clear_flags` is used.
pub(all) struct Context {
  rounding : RoundingMode
  tininess : TininessMode
  flags : ExceptionFlags
  specialization : Specialization
}

///|
/// Returns the default v1 context.
///
/// The defaults are round-near-even, tininess-after-rounding, no exception
/// flags, and the `X86_8086SSE` specialization. Boundary cases therefore use
/// the 8086-SSE default NaNs and invalid integer results unless the
/// specialization is changed explicitly.
pub fn Context::default() -> Context {
  {
    rounding: NearEven,
    tininess: AfterRounding,
    flags: ExceptionFlags::empty(),
    specialization: X86_8086SSE,
  }
}

///|
/// Returns the default RISCV specialization context.
///
/// Rounding, tininess, and flags match `Context::default`; only the
/// specialization changes. This affects default NaNs, NaN propagation details,
/// and invalid integer result constants for later operations.
pub fn Context::riscv() -> Context {
  { ..Context::default(), specialization: RISCV }
}

///|
/// Returns this context with a different rounding mode and unchanged flags.
///
/// Accumulated flags are intentionally preserved; call `clear_flags` first if
/// the new rounding mode should start a fresh operation log.
pub fn Context::with_rounding(
  self : Context,
  rounding : RoundingMode,
) -> Context {
  { ..self, rounding, }
}

///|
/// Returns this context with a different tininess mode and unchanged flags.
///
/// The mode only affects future underflow flag decisions.
pub fn Context::with_tininess(
  self : Context,
  tininess : TininessMode,
) -> Context {
  { ..self, tininess, }
}

///|
/// Returns this context with a different specialization and unchanged flags.
///
/// The new specialization only affects future operations. Already accumulated
/// flags remain as-is.
pub fn Context::with_specialization(
  self : Context,
  specialization : Specialization,
) -> Context {
  { ..self, specialization, }
}

///|
/// Returns this context with all accumulated exception flags cleared.
///
/// Rounding mode, tininess mode, and specialization are preserved.
pub fn Context::clear_flags(self : Context) -> Context {
  { ..self, flags: ExceptionFlags::empty() }
}

///|
/// Returns this context with `flags` accumulated.
///
/// MoonBit reserves `raise` as a keyword, so this method is named
/// `raise_flags` while preserving the explicit-flag accumulation semantics
/// specified by SoftFloat. Passing an empty flag set is a no-op; passing
/// multiple bits raises all of them at once.
pub fn Context::raise_flags(self : Context, flags : ExceptionFlags) -> Context {
  { ..self, flags: self.flags.merge(flags) }
}
