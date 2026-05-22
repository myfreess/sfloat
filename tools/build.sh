#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/berkeley-softfloat-3/source"
PLATFORM="$ROOT/berkeley-softfloat-3/build/Linux-x86_64-GCC"
ORACLE="$ROOT/tools/oracle.c"

if ! command -v gcc >/dev/null 2>&1; then
  echo "tools/build.sh: gcc is required" >&2
  exit 1
fi

mapfile -t GENERIC_SOURCES < <(
  find "$SRC" -maxdepth 1 -name '*.c' \
    ! -name '*extF80*' \
    ! -name '*ExtF80*' \
    ! -name '*f128*' \
    ! -name '*F128*' \
    ! -name '*M.c' \
    | sort
)

build_one() {
  local spec_dir="$1"
  local spec_name="$2"
  local output="$3"

  mapfile -t SPEC_SOURCES < <(
    find "$spec_dir" -maxdepth 1 -name '*.c' \
      ! -name '*extF80*' \
      ! -name '*ExtF80*' \
      ! -name '*f128*' \
      ! -name '*F128*' \
      ! -name '*M.c' \
      | sort
  )
  gcc \
    -std=c99 \
    -O2 \
    -DSOFTFLOAT_FAST_INT64 \
    -DSOFTFLOAT_ROUND_ODD \
    "-DORACLE_SPECIALIZATION=\"$spec_name\"" \
    -I"$PLATFORM" \
    -I"$SRC/include" \
    -I"$spec_dir" \
    "$ORACLE" \
    "${GENERIC_SOURCES[@]}" \
    "${SPEC_SOURCES[@]}" \
    -o "$output"
}

build_one "$SRC/8086-SSE" "x86_8086_sse" "$ROOT/tools/oracle-8086-sse"
build_one "$SRC/RISCV" "riscv" "$ROOT/tools/oracle-riscv"
