`timescale 1ns / 1ps

module lzc_128 (
    input  wire [127:0] in_bits,
    output wire [7:0]   zero_count,
    output wire         all_zeros
);

    wire [3:0]  sub_lzc [31:0];
    wire [31:0] sub_zero;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_lzc4
            lzc_4 u_lzc4 (
                .nibble  (in_bits[127 - 4*i : 124 - 4*i]),
                .count   (sub_lzc[i][1:0]),
                .is_zero (sub_zero[31 - i])
            );
            assign sub_lzc[i][3:2] = 2'b00;
        end
    endgenerate

    reg [4:0] block_idx;
    reg       block_valid;
    integer k;

    always @(*) begin
        block_idx   = 5'd0;
        block_valid = 1'b0;
        for (k = 0; k <= 31; k = k + 1) begin
            if (!sub_zero[k]) begin
                block_idx   = 5'd31 - k[4:0];
                block_valid = 1'b1;
            end
        end
    end

    assign all_zeros  = ~block_valid;
    assign zero_count = all_zeros ? 8'd128 : {1'b0, block_idx, sub_lzc[block_idx][1:0]};

endmodule

module lzc_4 (
    input  wire [3:0] nibble,
    output reg  [1:0] count,
    output wire       is_zero
);
    assign is_zero = (nibble == 4'b0000);

    always @(*) begin
        casez (nibble)
            4'b1???: count = 2'b00;
            4'b01??: count = 2'b01;
            4'b001?: count = 2'b10;
            4'b0001: count = 2'b11;
            default: count = 2'b00;
        endcase
    end
endmodule