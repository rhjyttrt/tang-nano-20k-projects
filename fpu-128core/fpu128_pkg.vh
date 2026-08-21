`ifndef fpu128_pkg_vh
`define fpu128_pkg_vh

`define fpu_op_add  2'b00
`define fpu_op_sub  2'b01
`define fpu_op_mul  2'b10

`define fpu_rnd_rne 2'b00
`define fpu_rnd_rtz 2'b01
`define fpu_rnd_rdn 2'b10
`define fpu_rnd_rup 2'b11

`define flag_invalid   0
`define flag_inexact   1
`define flag_underflow 2
`define flag_overflow  3

`endif