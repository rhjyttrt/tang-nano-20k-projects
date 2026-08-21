`timescale 1ns / 1ps
`include "fpu128_pkg.vh"

module fpu_add_sub (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire         sub_op,
    input  wire [127:0] a,
    input  wire [127:0] b,
    input  wire [1:0]   round_mode,

    output reg  [127:0] result,
    output reg  [3:0]   flags,
    output reg          done
);

    localparam idle      = 3'd0;
    localparam unpack    = 3'd1;
    localparam align     = 3'd2;
    localparam add       = 3'd3;
    localparam norm_cnt  = 3'd4;
    localparam norm_sft  = 3'd5;
    localparam round     = 3'd6;

    reg [2:0]   state;
    reg         sign_a, sign_b, sign_res;
    reg [14:0]  exp_a, exp_b;
    reg [16:0]  exp_res;
    reg [115:0] mant_a, mant_b;
    reg [118:0] mant_sum;
    reg         sticky_bit;
    reg         is_zero_op;

    wire [7:0] lzc_cnt;
    wire       lzc_zero;

    lzc_128 u_lzc (
        .in_bits    ({mant_sum[114:0], 13'b0}),
        .zero_count (lzc_cnt),
        .all_zeros  (lzc_zero)
    );

    wire [127:0] rounded_result;
    wire [3:0]   round_flags;

    fpu_round u_round (
        .sign       (sign_res),
        .exp_in     (exp_res),
        .mant_in    (mant_sum[114:1]),
        .sticky     (sticky_bit | mant_sum[0]),
        .round_mode (round_mode),
        .result     (rounded_result),
        .flags      (round_flags)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= idle;
            done       <= 1'b0;
            result     <= 128'b0;
            flags      <= 4'b0;
            sticky_bit <= 1'b0;
            is_zero_op <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                idle: begin
                    if (start) begin
                        sign_a <= a[127];
                        exp_a  <= a[126:112];
                        mant_a <= (a[126:112] == 0) ? {4'b0000, a[111:0]} : {4'b0001, a[111:0]};

                        sign_b <= b[127] ^ sub_op;
                        exp_b  <= b[126:112];
                        mant_b <= (b[126:112] == 0) ? {4'b0000, b[111:0]} : {4'b0001, b[111:0]};
                        state  <= unpack;
                    end
                end

                unpack: begin
                    if (exp_a >= exp_b) begin
                        exp_res  <= {2'b00, exp_a};
                        sign_res <= sign_a;
                        state    <= align;
                    end else begin
                        exp_res  <= {2'b00, exp_b};
                        mant_a   <= mant_b;
                        mant_b   <= mant_a;
                        sign_a   <= sign_b;
                        sign_b   <= sign_a;
                        sign_res <= sign_b;
                        exp_a    <= exp_b;
                        exp_b    <= exp_a;
                        state    <= align;
                    end
                end

                align: begin
                    if ((exp_a - exp_b) > 15'd115) begin
                        mant_b     <= 116'd0;
                        sticky_bit <= |mant_b;
                    end else begin
                        sticky_bit <= |(mant_b & ((116'd1 << (exp_a - exp_b)) - 116'd1));
                        mant_b     <= mant_b >> (exp_a - exp_b);
                    end
                    state <= add;
                end

                add: begin
                    if (sign_a == sign_b) begin
                        mant_sum <= {1'b0, mant_a, 2'b00} + {1'b0, mant_b, 2'b00};
                    end else begin
                        if (mant_a >= mant_b) begin
                            mant_sum <= {1'b0, mant_a, 2'b00} - {1'b0, mant_b, 2'b00};
                        end else begin
                            mant_sum <= {1'b0, mant_b, 2'b00} - {1'b0, mant_a, 2'b00};
                            sign_res <= ~sign_res;
                        end
                    end
                    state <= norm_cnt;
                end

                norm_cnt: begin
                    if (mant_sum[115]) begin
                        sticky_bit <= sticky_bit | mant_sum[0];
                        mant_sum   <= mant_sum >> 1;
                        exp_res    <= exp_res + 17'd1;
                        state      <= round;
                    end else if (lzc_zero || mant_sum == 0) begin
                        is_zero_op <= 1'b1;
                        sign_res   <= 1'b0;
                        state      <= round;
                    end else begin
                        state <= norm_sft;
                    end
                end

                norm_sft: begin
                    if ($signed(exp_res) > $signed({9'd0, lzc_cnt})) begin
                        mant_sum <= mant_sum << lzc_cnt;
                        exp_res  <= exp_res - {9'd0, lzc_cnt};
                    end else begin
                        mant_sum <= 119'd0;
                        exp_res  <= 17'd0;
                    end
                    state <= round;
                end

                round: begin
                    if (is_zero_op) begin
                        result <= 128'b0;
                        flags  <= 4'b0;
                    end else begin
                        result <= rounded_result;
                        flags  <= round_flags;
                    end
                    done       <= 1'b1;
                    is_zero_op <= 1'b0;
                    state      <= idle;
                end

                default: state <= idle;
            endcase
        end
    end

endmodule