# MoonBit SoftFloat

This repository is a pure MoonBit implementation of Soft Float.

The implementation keeps SoftFloat state explicit: operations thread a
`Context` value that carries rounding mode, tininess mode, exception flags, and
the selected specialization profile.