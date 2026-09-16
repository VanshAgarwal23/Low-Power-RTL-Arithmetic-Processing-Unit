`timescale 1ns/1ps

module pipelined_apu_tb;

    parameter WIDTH = 16;

    reg clk;
    reg rst;
    reg enable;
    reg [2:0] opcode;
    reg [WIDTH-1:0] A;
    reg [WIDTH-1:0] B;

    wire [2*WIDTH-1:0] result;
    wire [6:0] flags;
    wire valid;

    integer pass_count;
    integer fail_count;

    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_MUL = 3'b010;
    localparam OP_DIV = 3'b011;
    localparam OP_AND = 3'b100;
    localparam OP_OR  = 3'b101;
    localparam OP_XOR = 3'b110;
    localparam OP_NOT = 3'b111;

    pipelined_apu #(
        .WIDTH(WIDTH)
    ) dut (
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


    task check_operation;
        input [2:0] op;
        input [WIDTH-1:0] a;
        input [WIDTH-1:0] b;
        input [2*WIDTH-1:0] expected_result;

        begin

            @(negedge clk);

            opcode = op;
            A = a;
            B = b;
            enable = 1'b1;

            @(negedge clk);

            enable = 1'b0;

            @(negedge clk);

            if (valid && result == expected_result) begin
                pass_count = pass_count + 1;
                $display(
                    "PASS: opcode=%b A=%h B=%h result=%h flags=%b",
                    op, a, b, result, flags
                );
            end
            else begin
                fail_count = fail_count + 1;
                $display(
                    "FAIL: opcode=%b A=%h B=%h expected=%h got=%h valid=%b flags=%b",
                    op, a, b, expected_result, result, valid, flags
                );
            end

        end
    endtask


    initial begin

        clk = 1'b0;
        rst = 1'b1;
        enable = 1'b0;
        opcode = OP_ADD;
        A = 0;
        B = 0;

        pass_count = 0;
        fail_count = 0;

        /*
         * Reset
         */

        repeat (2)
            @(negedge clk);

        rst = 1'b0;


        /*
         * ADD tests
         */

        check_operation(OP_ADD, 16'd10, 16'd20, 32'd30);

      check_operation(
    OP_ADD,
    16'hFFFF,
    16'h0001,
    32'h00000000
);

        /*
         * SUB tests
         */

        check_operation(OP_SUB, 16'd50, 16'd20, 32'd30);

        check_operation(OP_SUB, 16'd20, 16'd50, 32'h0000FFE2);

        /*
         * MUL tests
         */

        check_operation(OP_MUL, 16'd10, 16'd20, 32'd200);

        check_operation(
            OP_MUL,
            16'hFFFF,
            16'hFFFF,
            32'hFFFE0001
        );


        /*
         * DIV tests
         */

        check_operation(OP_DIV, 16'd100, 16'd10, 32'd10);

        check_operation(OP_DIV, 16'd100, 16'd0, 32'd0);


        /*
         * Logic tests
         */

        check_operation(
            OP_AND,
            16'hAAAA,
            16'h5555,
            32'h00000000
        );

        check_operation(
            OP_OR,
            16'hAAAA,
            16'h5555,
            32'h0000FFFF
        );

        check_operation(
            OP_XOR,
            16'hAAAA,
            16'h5555,
            32'h0000FFFF
        );

        check_operation(
            OP_NOT,
            16'hAAAA,
            16'h0000,
            32'h00005555
        );
        /*
         * Additional boundary and flag tests
         */

        // ADD: carry generation
        check_operation(
            OP_ADD,
            16'hFFFF,
            16'h0001,
            32'h00000000
        );

        // ADD: signed positive overflow
        check_operation(
            OP_ADD,
            16'h7FFF,
            16'h0001,
            32'h00008000
        );

        // ADD: zero result
        check_operation(
            OP_ADD,
            16'h0000,
            16'h0000,
            32'h00000000
        );

        // SUB: zero result
        check_operation(
            OP_SUB,
            16'h1234,
            16'h1234,
            32'h00000000
        );

        // SUB: borrow
        check_operation(
            OP_SUB,
            16'h0000,
            16'h0001,
            32'h0000FFFF
        );

        // SUB: signed negative result
        check_operation(
            OP_SUB,
            16'h0005,
            16'h0008,
            32'h0000FFFD
        );

        // MUL: zero
        check_operation(
            OP_MUL,
            16'h0000,
            16'hFFFF,
            32'h00000000
        );

        // MUL: maximum value
        check_operation(
            OP_MUL,
            16'hFFFF,
            16'h0002,
            32'h0001FFFE
        );

        // DIV: exact division
        check_operation(
            OP_DIV,
            16'hFFFF,
            16'h000F,
            32'h00001111
        );

        // DIV: dividend smaller than divisor
        check_operation(
            OP_DIV,
            16'h0005,
            16'h000A,
            32'h00000000
        );

        // AND: all ones
        check_operation(
            OP_AND,
            16'hFFFF,
            16'hFFFF,
            32'h0000FFFF
        );

        // OR: zero operands
        check_operation(
            OP_OR,
            16'h0000,
            16'h0000,
            32'h00000000
        );

        // XOR: identical operands
        check_operation(
            OP_XOR,
            16'hAAAA,
            16'hAAAA,
            32'h00000000
        );

        // NOT: all zeros
        check_operation(
            OP_NOT,
            16'h0000,
            16'h0000,
            32'h0000FFFF
        );

        /*
         * Summary
         */

        $display("");
        $display("======================================");
        $display("PIPELINED APU VERIFICATION");
        $display("======================================");
        $display("PASS: %0d", pass_count);
        $display("FAIL: %0d", fail_count);
        $display("TOTAL: %0d", pass_count + fail_count);
        $display("======================================");

        $finish;

    end

endmodule
