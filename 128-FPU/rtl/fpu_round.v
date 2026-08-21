`timescale 1ns / 1ps
`include "fpu128_pkg.vh"

module fpu_round (
    input  wire         sign,
    input  wire [16:0]  exp_in,
    input  wire [113:0] mant_in,
    input  wire         sticky,
    input  wire [1:0]   round_mode,

    output reg  [127:0] result,
    output reg  [3:0]   flags
);

    wire guard = mant_in[0];
    wire lsb   = mant_in[1];
    reg  round_up;

    always @(*) begin
        case (round_mode)
            `fpu_rnd_rne: round_up = guard && (sticky || lsb);
            `fpu_rnd_rtz: round_up = 1'b0;
            `fpu_rnd_rdn: round_up = sign && (guard || sticky);
            `fpu_rnd_rup: round_up = !sign && (guard || sticky);
            default:      round_up = 1'b0;
        endcase
    end

    wire [114:0] mant_rounded = {1'b0, mant_in} + (round_up ? 115'd2 : 115'd0);
    wire mant_overflow = mant_rounded[114];

    reg [16:0]  exp_final;
    reg [111:0] frac_final;

    always @(*) begin
        flags = 4'b0000;
        if (guard || sticky) flags[`flag_inexact] = 1'b1;

        if (mant_overflow) begin
            exp_final  = exp_in + 17'd1;
            frac_final = mant_rounded[113:2];
        end else begin
            exp_final  = exp_in;
            frac_final = mant_rounded[112:1];
        end

        if ($signed(exp_final) >= 17'sd32767) begin
            flags[`flag_overflow] = 1'b1;
            flags[`flag_inexact]  = 1'b1;
            result = {sign, 15'h7fff, 112'b0};
        end else if ($signed(exp_final) <= 17'sd0) begin
            flags[`flag_underflow] = 1'b1;
            result = {sign, 15'd0, 112'b0};
        end else begin
            result = {sign, exp_final[14:0], frac_final};
        end
    end

endmodule