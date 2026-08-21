`timescale 1ns / 1ps
`include "fpu128_pkg.vh"

module fpu_mul (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [127:0] a,
    input  wire [127:0] b,
    input  wire [1:0]   round_mode,

    output reg  [127:0] result,
    output reg  [3:0]   flags,
    output reg          done
);

    localparam idle      = 3'd0;
    localparam load      = 3'd1;
    localparam mult      = 3'd2;
    localparam accum     = 3'd3;
    localparam norm      = 3'd4;
    localparam round     = 3'd5;

    reg [2:0]   state;
    reg         sign_res;
    reg [16:0]  exp_res;
    reg         is_zero_mul;

    reg [28:0]  a_chunks [3:0];
    reg [28:0]  b_chunks [3:0];
    reg [3:0]   step_cnt;

    reg [57:0]  m_prod;
    reg [231:0] mant_accum;

    wire [1:0] cur_i = step_cnt[3:2];
    wire [1:0] cur_j = step_cnt[1:0];

    wire [127:0] rounded_result;
    wire [3:0]   round_flags;

    fpu_round u_round (
        .sign       (sign_res),
        .exp_in     (exp_res),
        .mant_in    (mant_accum[224:111]),
        .sticky     (|mant_accum[110:0]),
        .round_mode (round_mode),
        .result     (rounded_result),
        .flags      (round_flags)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= idle;
            done        <= 1'b0;
            result      <= 128'b0;
            flags       <= 4'b0;
            mant_accum  <= 232'b0;
            is_zero_mul <= 1'b0;
            step_cnt    <= 4'd0;
            m_prod      <= 58'd0;
        end else begin
            done <= 1'b0;
            case (state)
                idle: begin
                    if (start) begin
                        sign_res <= a[127] ^ b[127];
                        if (a[126:112] == 0 || b[126:112] == 0) begin
                            is_zero_mul <= 1'b1;
                            state       <= round;
                        end else begin
                            is_zero_mul <= 1'b0;
                            exp_res     <= {2'b00, a[126:112]} + {2'b00, b[126:112]} - 17'd16383;
                            state       <= load;
                        end
                    end
                end

                load: begin
                    a_chunks[0] <= a[28:0];
                    a_chunks[1] <= a[57:29];
                    a_chunks[2] <= a[86:58];
                    a_chunks[3] <= {3'b000, 1'b1, a[111:87]};

                    b_chunks[0] <= b[28:0];
                    b_chunks[1] <= b[57:29];
                    b_chunks[2] <= b[86:58];
                    b_chunks[3] <= {3'b000, 1'b1, b[111:87]};

                    mant_accum  <= 232'b0;
                    step_cnt    <= 4'd0;
                    state       <= mult;
                end

                mult: begin
                    m_prod <= a_chunks[cur_i] * b_chunks[cur_j];
                    state  <= accum;
                end

                accum: begin
                    mant_accum <= mant_accum + ({174'd0, m_prod} << ((cur_i + cur_j) * 29));
                    if (step_cnt == 4'd15) begin
                        state <= norm;
                    end else begin
                        step_cnt <= step_cnt + 1'b1;
                        state    <= mult;
                    end
                end

                norm: begin
                    if (mant_accum[225]) begin
                        mant_accum <= mant_accum >> 1;
                        exp_res    <= exp_res + 17'd1;
                    end
                    state <= round;
                end

                round: begin
                    if (is_zero_mul) begin
                        result <= {sign_res, 127'b0};
                        flags  <= 4'b0;
                    end else begin
                        result <= rounded_result;
                        flags  <= round_flags;
                    end
                    done        <= 1'b1;
                    is_zero_mul <= 1'b0;
                    state       <= idle;
                end

                default: state <= idle;
            endcase
        end
    end

endmodule