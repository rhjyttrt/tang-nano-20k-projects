`timescale 1ns / 1ps
`include "../fpu128_pkg.vh"

module tb_fpu128;

    reg clk;
    reg rst_n;
    reg start;
    reg [1:0] opcode;
    reg [1:0] round_mode;
    reg [127:0] op_a;
    reg [127:0] op_b;

    wire ready;
    wire done;
    wire [127:0] result;
    wire [3:0] flags;

    fpu_top dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .ready      (ready),
        .opcode     (opcode),
        .round_mode (round_mode),
        .op_a       (op_a),
        .op_b       (op_b),
        .result     (result),
        .done       (done),
        .flags      (flags)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        opcode = 0;
        round_mode = `fpu_rnd_rne;
        op_a = 128'b0;
        op_b = 128'b0;

        #20 rst_n = 1;
        #10;

        @(posedge clk);
        op_a = 128'h3fff0000000000000000000000000000;
        op_b = 128'h40000000000000000000000000000000;
        opcode = `fpu_op_add;
        start = 1;
        @(posedge clk);
        start = 0;

        @(posedge done);
        #1;
        $display("[add] 1.0 + 2.0 = %h", result);

        @(posedge clk);
        op_a = 128'h40008000000000000000000000000000;
        op_b = 128'h40000000000000000000000000000000;
        opcode = `fpu_op_mul;
        start = 1;
        @(posedge clk);
        start = 0;

        @(posedge done);
        #1;
        $display("[mul] 3.0 * 2.0 = %h", result);

        #50;
        $finish;
    end

endmodule