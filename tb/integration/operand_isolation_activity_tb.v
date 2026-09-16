`timescale 1ns/1ps

module operand_isolation_activity_tb;

    reg         clk;
    reg         rst;
    reg         enable;
    reg  [2:0]  opcode;
    reg  [15:0] A;
    reg  [15:0] B;

    localparam ADD = 3'b000;
    localparam SUB = 3'b001;
    localparam MUL = 3'b010;
    localparam DIV = 3'b011;
    localparam AND_OP = 3'b100;
    localparam OR_OP  = 3'b101;
    localparam XOR_OP = 3'b110;
    localparam NOT_OP = 3'b111;

    wire [31:0] result;
    wire [6:0]  flags;
    wire        valid;

    low_power_apu dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .opcode(opcode),
        .A(A),
        .B(B),
        .result(result),
        .flags(flags),
        .valid(valid)
    );

    always #5 clk = ~clk;

    integer i;

    initial begin

        $dumpfile("sim/operand_isolation_activity.vcd");
        $dumpvars(0, operand_isolation_activity_tb);

        clk    = 1'b0;
        rst    = 1'b1;
        enable = 1'b0;
        opcode = ADD;
        A      = 16'h0000;
        B      = 16'h0000;

        repeat (2) @(posedge clk);
        rst = 1'b0;

        /*
         * ADD phase:
         * A and B change continuously while ADD remains selected.
         * SUB/MUL/DIV/LOGIC inputs should remain isolated.
         */
        opcode = ADD;
        enable = 1'b1;

        for (i = 0; i < 200; i = i + 1) begin
            @(negedge clk);
            A = (16'h1234 ^ i);
            B = (16'hABCD + i);
        end

        /*
         * MUL phase
         */
        opcode = MUL;

        for (i = 0; i < 200; i = i + 1) begin
            @(negedge clk);
            A = (16'hAAAA ^ (i * 17));
            B = (16'h5555 + (i * 13));
        end

        /*
         * DIV phase
         */
        opcode = DIV;

        for (i = 0; i < 200; i = i + 1) begin
            @(negedge clk);
            A = (16'hF000 ^ (i * 23));
            B = (16'h0011 + (i % 31));
        end

        /*
         * LOGIC phase
         */
        opcode = XOR_OP;

        for (i = 0; i < 200; i = i + 1) begin
            @(negedge clk);
            A = (16'hAAAA ^ (i * 37));
            B = (16'h5555 ^ (i * 19));
        end

        /*
         * Idle phase:
         * Inputs continue changing while enable is low.
         * All computational blocks should remain isolated.
         */
        enable = 1'b0;

        for (i = 0; i < 200; i = i + 1) begin
            @(negedge clk);
            A = i * 97;
            B = i * 193;
        end

        enable = 1'b0;

        repeat (5) @(posedge clk);

        $display("==============================================");
        $display(" OPERAND ISOLATION ACTIVITY TEST COMPLETE");
        $display("==============================================");

        $finish;
    end

endmodule
