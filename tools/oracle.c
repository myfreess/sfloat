/*
 * SoftFloat v1 golden oracle CLI.
 *
 * Usage:
 *   oracle <operation> <rounding> <tininess> <exact> <hex-input>...
 *   oracle --batch <operation> <rounding> <tininess> <exact> < hex-input-lines
 *
 * The binary is built twice, once per specialization.  It prints one
 * line-oriented record:
 *   specialization operation rounding tininess exact inputs... output flags
 *
 * Integer outputs are printed as fixed-width two's-complement hex so invalid
 * result constants can be compared without host-width ambiguity.
 */

#include <errno.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

#include "softfloat.h"

#ifndef ORACLE_SPECIALIZATION
#define ORACLE_SPECIALIZATION "unknown"
#endif

typedef enum {
    OUT_HEX16,
    OUT_HEX32,
    OUT_HEX64,
    OUT_BOOL
} output_kind_t;

static void fail( const char *message )
{
    fprintf( stderr, "oracle: %s\n", message );
    exit( 2 );
}

static bool streq( const char *a, const char *b )
{
    return strcmp( a, b ) == 0;
}

static uint64_t parse_hex64( const char *text )
{
    while ( text[0] == '0' && (text[1] == 'x' || text[1] == 'X') ) {
        text += 2;
    }
    errno = 0;
    char *end = NULL;
    uint64_t value = strtoull( text, &end, 16 );
    if ( errno || ! end || *end ) fail( "invalid hex input" );
    return value;
}

static uint_fast8_t parse_rounding( const char *text )
{
    if ( streq( text, "0" ) || streq( text, "near_even" ) ) return softfloat_round_near_even;
    if ( streq( text, "1" ) || streq( text, "min_mag" ) ) return softfloat_round_minMag;
    if ( streq( text, "2" ) || streq( text, "min" ) ) return softfloat_round_min;
    if ( streq( text, "3" ) || streq( text, "max" ) ) return softfloat_round_max;
    if ( streq( text, "4" ) || streq( text, "near_max_mag" ) ) return softfloat_round_near_maxMag;
    if ( streq( text, "6" ) || streq( text, "odd" ) ) return softfloat_round_odd;
    fail( "invalid rounding mode" );
    return 0;
}

static const char *rounding_name( uint_fast8_t rounding )
{
    switch ( rounding ) {
    case softfloat_round_near_even: return "near_even";
    case softfloat_round_minMag: return "min_mag";
    case softfloat_round_min: return "min";
    case softfloat_round_max: return "max";
    case softfloat_round_near_maxMag: return "near_max_mag";
    case softfloat_round_odd: return "odd";
    default: return "unknown";
    }
}

static uint_fast8_t parse_tininess( const char *text )
{
    if ( streq( text, "0" ) || streq( text, "before" ) ) return softfloat_tininess_beforeRounding;
    if ( streq( text, "1" ) || streq( text, "after" ) ) return softfloat_tininess_afterRounding;
    fail( "invalid tininess mode" );
    return 0;
}

static const char *tininess_name( uint_fast8_t tininess )
{
    switch ( tininess ) {
    case softfloat_tininess_beforeRounding: return "before";
    case softfloat_tininess_afterRounding: return "after";
    default: return "unknown";
    }
}

static bool parse_exact( const char *text )
{
    if ( streq( text, "1" ) || ! strcasecmp( text, "true" ) ) return true;
    if ( streq( text, "0" ) || ! strcasecmp( text, "false" ) ) return false;
    fail( "invalid exact flag" );
    return false;
}

static float16_t make_f16( uint64_t bits )
{
    float16_t value = { (uint16_t) bits };
    return value;
}

static bfloat16_t make_bf16( uint64_t bits )
{
    bfloat16_t value = { (uint16_t) bits };
    return value;
}

static float32_t make_f32( uint64_t bits )
{
    float32_t value = { (uint32_t) bits };
    return value;
}

static float64_t make_f64( uint64_t bits )
{
    float64_t value = { bits };
    return value;
}

static void require_inputs( int actual, int expected )
{
    if ( actual != expected ) fail( "wrong number of inputs for operation" );
}

static void print_record(
    const char *op,
    uint_fast8_t rounding,
    uint_fast8_t tininess,
    bool exact,
    int input_count,
    char **inputs,
    output_kind_t kind,
    uint64_t output
)
{
    printf(
        "%s %s %s %s %u",
        ORACLE_SPECIALIZATION,
        op,
        rounding_name( rounding ),
        tininess_name( tininess ),
        exact ? 1U : 0U
    );
    for ( int i = 0; i < input_count; ++i ) {
        printf( " %s", inputs[i] );
    }
    switch ( kind ) {
    case OUT_HEX16:
        printf( " %04" PRIX64, output & UINT64_C( 0xFFFF ) );
        break;
    case OUT_HEX32:
        printf( " %08" PRIX64, output & UINT64_C( 0xFFFFFFFF ) );
        break;
    case OUT_HEX64:
        printf( " %016" PRIX64, output );
        break;
    case OUT_BOOL:
        printf( " %u", output ? 1U : 0U );
        break;
    }
    printf( " %02X\n", (unsigned) softfloat_exceptionFlags );
}

static int emit(
    const char *op,
    uint_fast8_t rounding,
    uint_fast8_t tininess,
    bool exact,
    int input_count,
    char **inputs,
    output_kind_t kind,
    uint64_t output
)
{
    print_record( op, rounding, tininess, exact, input_count, inputs, kind, output );
    return 0;
}

static int run_operation(
    const char *op,
    uint_fast8_t rounding,
    uint_fast8_t tininess,
    bool exact,
    int input_count,
    char **inputs
)
{
    softfloat_roundingMode = rounding;
    softfloat_detectTininess = tininess;
    softfloat_exceptionFlags = 0;

    uint64_t a0 = input_count > 0 ? parse_hex64( inputs[0] ) : 0;
    uint64_t a1 = input_count > 1 ? parse_hex64( inputs[1] ) : 0;
    uint64_t a2 = input_count > 2 ? parse_hex64( inputs[2] ) : 0;

    if ( streq( op, "ui32_to_f16" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, ui32_to_f16( (uint32_t) a0 ).v );
    }
    if ( streq( op, "ui32_to_f32" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, ui32_to_f32( (uint32_t) a0 ).v );
    }
    if ( streq( op, "ui32_to_f64" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, ui32_to_f64( (uint32_t) a0 ).v );
    }
    if ( streq( op, "ui64_to_f16" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, ui64_to_f16( a0 ).v );
    }
    if ( streq( op, "ui64_to_f32" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, ui64_to_f32( a0 ).v );
    }
    if ( streq( op, "ui64_to_f64" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, ui64_to_f64( a0 ).v );
    }
    if ( streq( op, "i32_to_f16" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, i32_to_f16( (int32_t) (uint32_t) a0 ).v );
    }
    if ( streq( op, "i32_to_f32" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, i32_to_f32( (int32_t) (uint32_t) a0 ).v );
    }
    if ( streq( op, "i32_to_f64" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, i32_to_f64( (int32_t) (uint32_t) a0 ).v );
    }
    if ( streq( op, "i64_to_f16" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, i64_to_f16( (int64_t) a0 ).v );
    }
    if ( streq( op, "i64_to_f32" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, i64_to_f32( (int64_t) a0 ).v );
    }
    if ( streq( op, "i64_to_f64" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, i64_to_f64( (int64_t) a0 ).v );
    }

    if ( streq( op, "bf16_to_f32" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, bf16_to_f32( make_bf16( a0 ) ).v );
    }
    if ( streq( op, "f32_to_bf16" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, f32_to_bf16( make_f32( a0 ) ).v );
    }
    if ( streq( op, "bf16_is_signaling_nan" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, bf16_isSignalingNaN( make_bf16( a0 ) ) );
    }

    if ( streq( op, "f16_to_ui32" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, (uint32_t) f16_to_ui32( make_f16( a0 ), rounding, exact ) );
    }
    if ( streq( op, "f16_to_ui64" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, (uint64_t) f16_to_ui64( make_f16( a0 ), rounding, exact ) );
    }
    if ( streq( op, "f16_to_i32" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, (uint32_t) (int32_t) f16_to_i32( make_f16( a0 ), rounding, exact ) );
    }
    if ( streq( op, "f16_to_i64" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, (uint64_t) (int64_t) f16_to_i64( make_f16( a0 ), rounding, exact ) );
    }
    if ( streq( op, "f16_to_ui32_min_mag" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, (uint32_t) f16_to_ui32_r_minMag( make_f16( a0 ), exact ) );
    }
    if ( streq( op, "f16_to_ui64_min_mag" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, (uint64_t) f16_to_ui64_r_minMag( make_f16( a0 ), exact ) );
    }
    if ( streq( op, "f16_to_i32_min_mag" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, (uint32_t) (int32_t) f16_to_i32_r_minMag( make_f16( a0 ), exact ) );
    }
    if ( streq( op, "f16_to_i64_min_mag" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, (uint64_t) (int64_t) f16_to_i64_r_minMag( make_f16( a0 ), exact ) );
    }
    if ( streq( op, "f16_to_f32" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, f16_to_f32( make_f16( a0 ) ).v );
    }
    if ( streq( op, "f16_to_f64" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, f16_to_f64( make_f16( a0 ) ).v );
    }
    if ( streq( op, "f16_round_to_int" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, f16_roundToInt( make_f16( a0 ), rounding, exact ).v );
    }
    if ( streq( op, "f16_add" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, f16_add( make_f16( a0 ), make_f16( a1 ) ).v );
    }
    if ( streq( op, "f16_sub" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, f16_sub( make_f16( a0 ), make_f16( a1 ) ).v );
    }
    if ( streq( op, "f16_mul" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, f16_mul( make_f16( a0 ), make_f16( a1 ) ).v );
    }
    if ( streq( op, "f16_mul_add" ) ) {
        require_inputs( input_count, 3 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, f16_mulAdd( make_f16( a0 ), make_f16( a1 ), make_f16( a2 ) ).v );
    }
    if ( streq( op, "f16_div" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, f16_div( make_f16( a0 ), make_f16( a1 ) ).v );
    }
    if ( streq( op, "f16_rem" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, f16_rem( make_f16( a0 ), make_f16( a1 ) ).v );
    }
    if ( streq( op, "f16_sqrt" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, f16_sqrt( make_f16( a0 ) ).v );
    }
    if ( streq( op, "f16_eq" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f16_eq( make_f16( a0 ), make_f16( a1 ) ) );
    }
    if ( streq( op, "f16_le" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f16_le( make_f16( a0 ), make_f16( a1 ) ) );
    }
    if ( streq( op, "f16_lt" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f16_lt( make_f16( a0 ), make_f16( a1 ) ) );
    }
    if ( streq( op, "f16_eq_signaling" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f16_eq_signaling( make_f16( a0 ), make_f16( a1 ) ) );
    }
    if ( streq( op, "f16_le_quiet" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f16_le_quiet( make_f16( a0 ), make_f16( a1 ) ) );
    }
    if ( streq( op, "f16_lt_quiet" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f16_lt_quiet( make_f16( a0 ), make_f16( a1 ) ) );
    }
    if ( streq( op, "f16_is_signaling_nan" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f16_isSignalingNaN( make_f16( a0 ) ) );
    }

    if ( streq( op, "f32_to_ui32" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, (uint32_t) f32_to_ui32( make_f32( a0 ), rounding, exact ) );
    }
    if ( streq( op, "f32_to_ui64" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, (uint64_t) f32_to_ui64( make_f32( a0 ), rounding, exact ) );
    }
    if ( streq( op, "f32_to_i32" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, (uint32_t) (int32_t) f32_to_i32( make_f32( a0 ), rounding, exact ) );
    }
    if ( streq( op, "f32_to_i64" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, (uint64_t) (int64_t) f32_to_i64( make_f32( a0 ), rounding, exact ) );
    }
    if ( streq( op, "f32_to_ui32_min_mag" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, (uint32_t) f32_to_ui32_r_minMag( make_f32( a0 ), exact ) );
    }
    if ( streq( op, "f32_to_ui64_min_mag" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, (uint64_t) f32_to_ui64_r_minMag( make_f32( a0 ), exact ) );
    }
    if ( streq( op, "f32_to_i32_min_mag" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, (uint32_t) (int32_t) f32_to_i32_r_minMag( make_f32( a0 ), exact ) );
    }
    if ( streq( op, "f32_to_i64_min_mag" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, (uint64_t) (int64_t) f32_to_i64_r_minMag( make_f32( a0 ), exact ) );
    }
    if ( streq( op, "f32_to_f16" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, f32_to_f16( make_f32( a0 ) ).v );
    }
    if ( streq( op, "f32_to_f64" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, f32_to_f64( make_f32( a0 ) ).v );
    }
    if ( streq( op, "f32_round_to_int" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, f32_roundToInt( make_f32( a0 ), rounding, exact ).v );
    }
    if ( streq( op, "f32_add" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, f32_add( make_f32( a0 ), make_f32( a1 ) ).v );
    }
    if ( streq( op, "f32_sub" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, f32_sub( make_f32( a0 ), make_f32( a1 ) ).v );
    }
    if ( streq( op, "f32_mul" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, f32_mul( make_f32( a0 ), make_f32( a1 ) ).v );
    }
    if ( streq( op, "f32_mul_add" ) ) {
        require_inputs( input_count, 3 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, f32_mulAdd( make_f32( a0 ), make_f32( a1 ), make_f32( a2 ) ).v );
    }
    if ( streq( op, "f32_div" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, f32_div( make_f32( a0 ), make_f32( a1 ) ).v );
    }
    if ( streq( op, "f32_rem" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, f32_rem( make_f32( a0 ), make_f32( a1 ) ).v );
    }
    if ( streq( op, "f32_sqrt" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, f32_sqrt( make_f32( a0 ) ).v );
    }
    if ( streq( op, "f32_eq" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f32_eq( make_f32( a0 ), make_f32( a1 ) ) );
    }
    if ( streq( op, "f32_le" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f32_le( make_f32( a0 ), make_f32( a1 ) ) );
    }
    if ( streq( op, "f32_lt" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f32_lt( make_f32( a0 ), make_f32( a1 ) ) );
    }
    if ( streq( op, "f32_eq_signaling" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f32_eq_signaling( make_f32( a0 ), make_f32( a1 ) ) );
    }
    if ( streq( op, "f32_le_quiet" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f32_le_quiet( make_f32( a0 ), make_f32( a1 ) ) );
    }
    if ( streq( op, "f32_lt_quiet" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f32_lt_quiet( make_f32( a0 ), make_f32( a1 ) ) );
    }
    if ( streq( op, "f32_is_signaling_nan" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f32_isSignalingNaN( make_f32( a0 ) ) );
    }

    if ( streq( op, "f64_to_ui32" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, (uint32_t) f64_to_ui32( make_f64( a0 ), rounding, exact ) );
    }
    if ( streq( op, "f64_to_ui64" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, (uint64_t) f64_to_ui64( make_f64( a0 ), rounding, exact ) );
    }
    if ( streq( op, "f64_to_i32" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, (uint32_t) (int32_t) f64_to_i32( make_f64( a0 ), rounding, exact ) );
    }
    if ( streq( op, "f64_to_i64" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, (uint64_t) (int64_t) f64_to_i64( make_f64( a0 ), rounding, exact ) );
    }
    if ( streq( op, "f64_to_ui32_min_mag" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, (uint32_t) f64_to_ui32_r_minMag( make_f64( a0 ), exact ) );
    }
    if ( streq( op, "f64_to_ui64_min_mag" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, (uint64_t) f64_to_ui64_r_minMag( make_f64( a0 ), exact ) );
    }
    if ( streq( op, "f64_to_i32_min_mag" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, (uint32_t) (int32_t) f64_to_i32_r_minMag( make_f64( a0 ), exact ) );
    }
    if ( streq( op, "f64_to_i64_min_mag" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, (uint64_t) (int64_t) f64_to_i64_r_minMag( make_f64( a0 ), exact ) );
    }
    if ( streq( op, "f64_to_f16" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX16, f64_to_f16( make_f64( a0 ) ).v );
    }
    if ( streq( op, "f64_to_f32" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX32, f64_to_f32( make_f64( a0 ) ).v );
    }
    if ( streq( op, "f64_round_to_int" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, f64_roundToInt( make_f64( a0 ), rounding, exact ).v );
    }
    if ( streq( op, "f64_add" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, f64_add( make_f64( a0 ), make_f64( a1 ) ).v );
    }
    if ( streq( op, "f64_sub" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, f64_sub( make_f64( a0 ), make_f64( a1 ) ).v );
    }
    if ( streq( op, "f64_mul" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, f64_mul( make_f64( a0 ), make_f64( a1 ) ).v );
    }
    if ( streq( op, "f64_mul_add" ) ) {
        require_inputs( input_count, 3 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, f64_mulAdd( make_f64( a0 ), make_f64( a1 ), make_f64( a2 ) ).v );
    }
    if ( streq( op, "f64_div" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, f64_div( make_f64( a0 ), make_f64( a1 ) ).v );
    }
    if ( streq( op, "f64_rem" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, f64_rem( make_f64( a0 ), make_f64( a1 ) ).v );
    }
    if ( streq( op, "f64_sqrt" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_HEX64, f64_sqrt( make_f64( a0 ) ).v );
    }
    if ( streq( op, "f64_eq" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f64_eq( make_f64( a0 ), make_f64( a1 ) ) );
    }
    if ( streq( op, "f64_le" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f64_le( make_f64( a0 ), make_f64( a1 ) ) );
    }
    if ( streq( op, "f64_lt" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f64_lt( make_f64( a0 ), make_f64( a1 ) ) );
    }
    if ( streq( op, "f64_eq_signaling" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f64_eq_signaling( make_f64( a0 ), make_f64( a1 ) ) );
    }
    if ( streq( op, "f64_le_quiet" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f64_le_quiet( make_f64( a0 ), make_f64( a1 ) ) );
    }
    if ( streq( op, "f64_lt_quiet" ) ) {
        require_inputs( input_count, 2 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f64_lt_quiet( make_f64( a0 ), make_f64( a1 ) ) );
    }
    if ( streq( op, "f64_is_signaling_nan" ) ) {
        require_inputs( input_count, 1 );
        return emit( op, rounding, tininess, exact, input_count, inputs, OUT_BOOL, f64_isSignalingNaN( make_f64( a0 ) ) );
    }

    fail( "operation is not in the v1 oracle surface" );
    return 2;
}

static int run_batch(
    const char *op,
    uint_fast8_t rounding,
    uint_fast8_t tininess,
    bool exact
)
{
    char line[512];
    while ( fgets( line, sizeof line, stdin ) ) {
        char *inputs[4];
        int input_count = 0;

        char *token = strtok( line, " \t\r\n" );
        if ( ! token || token[0] == '#' ) continue;
        while ( token ) {
            if ( input_count == 4 ) fail( "too many batch inputs" );
            inputs[input_count++] = token;
            token = strtok( NULL, " \t\r\n" );
        }
        run_operation( op, rounding, tininess, exact, input_count, inputs );
    }
    if ( ferror( stdin ) ) fail( "failed to read batch input" );
    return 0;
}

int main( int argc, char **argv )
{
    if ( argc >= 2 && streq( argv[1], "--batch" ) ) {
        if ( argc != 6 ) {
            fail( "usage: oracle --batch <operation> <rounding> <tininess> <exact> < hex-input-lines" );
        }
        return run_batch(
            argv[2],
            parse_rounding( argv[3] ),
            parse_tininess( argv[4] ),
            parse_exact( argv[5] )
        );
    }
    if ( argc < 5 ) {
        fail( "usage: oracle <operation> <rounding> <tininess> <exact> <hex-input>..." );
    }
    return run_operation(
        argv[1],
        parse_rounding( argv[2] ),
        parse_tininess( argv[3] ),
        parse_exact( argv[4] ),
        argc - 5,
        argv + 5
    );
}
