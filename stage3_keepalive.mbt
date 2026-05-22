///|
// Stage 3 rounding helpers are private until conversion operations call them.
fn init {
  let context = Context::default()
  ignore(round_inexact_context(context, true))
  ignore(round_invalid_context(context))
  ignore(round_to_ui32(context, false, 0UL, NearEven, true))
  ignore(round_to_ui64(context, false, 0UL, 0UL, NearEven, true))
  ignore(round_to_i32(context, false, 0UL, NearEven, true))
  ignore(round_to_i64(context, false, 0UL, 0UL, NearEven, true))
  ignore(norm_subnormal_f16_sig(1))
  ignore(norm_subnormal_bf16_sig(1))
  ignore(norm_subnormal_f32_sig(1U))
  ignore(norm_subnormal_f64_sig(1UL))
  ignore(round_pack_to_f16(context, false, 0, 0U))
  ignore(round_pack_to_bf16(context, false, 0, 0U))
  ignore(round_pack_to_f32(context, false, 0, 0U))
  ignore(round_pack_to_f64(context, false, 0, 0UL))
  ignore(norm_round_pack_to_f16(context, false, 0, 1U))
  ignore(norm_round_pack_to_f32(context, false, 0, 1U))
  ignore(norm_round_pack_to_f64(context, false, 0, 1UL))
}
