`timescale 1ns / 1ps
`include "fpu128_pkg.vh"

module fpu_top (
    input  wire         clk,
    input  wire         rst_n,

    input  wire         start,
    output wire         ready,
    input  wire [1:0]   opcode,
    input  wire [1:0]   round_mode,
    input  wire [127:0] op_a,
    input  wire [127:0] op_b,

    output reg  [127:0] result,
    output reg          done,
    output wire [3:0]   flags
);

    reg busy;
    assign ready = !busy;

    reg [3:0] flags_reg;
    assign flags = flags_reg;

    wire        add_sub_done, mul_done;
    wire [127:0] add_sub_res, mul_res;
    wire [3:0]  add_sub_flags, mul_flags;
    reg         add_sub_start, mul_start;

    wire is_mul     = (opcode == `fpu_op_mul);
    wire is_add_sub = (opcode == `fpu_op_add || opcode == `fpu_op_sub);
    wire is_invalid = !is_mul && !is_add_sub;
    wire sub_flag   = (opcode == `fpu_op_sub);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy          <= 1'b0;
            done          <= 1'b0;
            result        <= 128'b0;
            flags_reg     <= 4'b0;
            add_sub_start <= 1'b0;
            mul_start     <= 1'b0;
        end else begin
            done          <= 1'b0;
            add_sub_start <= 1'b0;
            mul_start     <= 1'b0;

            if (start && !busy) begin
                if (is_invalid) begin
                    result    <= 128'b0;
                    flags_reg <= 4'b0001;
                    done      <= 1'b1;
                    busy      <= 1'b0;
                end else begin
                    busy          <= 1'b1;
                    add_sub_start <= is_add_sub;
                    mul_start     <= is_mul;
                end
            end else if (busy) begin
                if (is_add_sub && add_sub_done) begin
                    result    <= add_sub_res;
                    flags_reg <= add_sub_flags;
                    done      <= 1'b1;
                    busy      <= 1'b0;
                end else if (is_mul && mul_done) begin
                    result    <= mul_res;
                    flags_reg <= mul_flags;
                    done      <= 1'b1;
                    busy      <= 1'b0;
                end
            end
        end
    end

    fpu_add_sub u_add_sub (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (add_sub_start),
        .sub_op     (sub_flag),
        .a          (op_a),
        .b          (op_b),
        .round_mode (round_mode),
        .result     (add_sub_res),
        .flags      (add_sub_flags),
        .done       (add_sub_done)
    );

    fpu_mul u_mul (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (mul_start),
        .a          (op_a),
        .b          (op_b),
        .round_mode (round_mode),
        .result     (mul_res),
        .flags      (mul_flags),
        .done       (mul_done)
    );

endmodule