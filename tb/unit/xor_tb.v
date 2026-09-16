`timescale 1ns/1ps

module xor_tb;

    parameter WIDTH = 16;

    reg  [WIDTH-1:0] a;
    reg  [WIDTH-1:0] b;
    reg  [2:0] opcode;

    wire [WIDTH-1:0] result;

    reg [WIDTH-1:0] expected;

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    logic_unit #(
        .WIDTH(WIDTH)
    ) dut (
        .a(a),
        .b(b),
        .opcode(opcode),
        .result(result)
    );

    task check_xor;
        input [WIDTH-1:0] a_in;
        input [WIDTH-1:0] b_in;
        input [255:0] test_name;

        begin
            a = a_in;
            b = b_in;
            opcode = 3'b110;

            #1;

            expected = a_in ^ b_in;

            total_tests = total_tests + 1;

            if (result === expected) begin
                passed_tests = passed_tests + 1;

                $display(
                    "[PASS] %-25s | A=%h B=%h | RESULT=%h",
                    test_name, a, b, result
                );
            end
            else begin
                failed_tests = failed_tests + 1;

                $display(
                    "[FAIL] %-25s | A=%h B=%h | Expected=%h | Got=%h",
                    test_name, a, b, expected, result
                );
            end
        end
    endtask

    initial begin

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        $dumpfile("sim/xor.vcd");
        $dumpvars(0, xor_tb);

        $display("");
        $display("==============================================");
        $display("          16-BIT XOR VERIFICATION");
        $display("==============================================");
        $display("");

        // Basic cases
        check_xor(16'h0000, 16'h0000, "ZERO XOR ZERO");
        check_xor(16'hFFFF, 16'hFFFF, "MAX XOR MAX");
        check_xor(16'hFFFF, 16'h0000, "MAX XOR ZERO");
        check_xor(16'h0000, 16'hFFFF, "ZERO XOR MAX");

        // Single-bit cases
        check_xor(16'h0001, 16'h0001, "BIT 0");
        check_xor(16'h0002, 16'h0002, "BIT 1");
        check_xor(16'h0004, 16'h0004, "BIT 2");
        check_xor(16'h8000, 16'h8000, "MSB");

        // Complementary patterns
        check_xor(16'hAAAA, 16'h5555, "AAAA XOR 5555");
        check_xor(16'h5555, 16'hAAAA, "5555 XOR AAAA");

        check_xor(16'hF0F0, 16'h0F0F, "F0F0 XOR 0F0F");
        check_xor(16'hCCCC, 16'h3333, "CCCC XOR 3333");

        // Partial overlaps
        check_xor(16'hFFFF, 16'hAAAA, "FFFF XOR AAAA");
        check_xor(16'hFFFF, 16'h5555, "FFFF XOR 5555");

        check_xor(16'hFF00, 16'h0FF0, "FF00 XOR 0FF0");
        check_xor(16'h0FF0, 16'h00FF, "0FF0 XOR 00FF");

        // Boundary patterns
        check_xor(16'h7FFF, 16'h8000, "SIGN BOUNDARY");
        check_xor(16'h00FF, 16'hFF00, "BYTE BOUNDARY");
        check_xor(16'h0FFF, 16'hF000, "12-BIT BOUNDARY");

        // Randomized verification
        repeat (1000) begin
            check_xor(
                $urandom_range(0, 16'hFFFF),
                $urandom_range(0, 16'hFFFF),
                "RANDOMIZED TEST"
            );
        end

        $display("");
        $display("==============================================");
        $display("             XOR TEST SUMMARY");
        $display("==============================================");
        $display("Total Tests : %0d", total_tests);
        $display("Passed      : %0d", passed_tests);
        $display("Failed      : %0d", failed_tests);
        $display("==============================================");

        if (failed_tests == 0)
            $display("***** 16-BIT XOR TEST: PASS *****");
        else
            $display("***** 16-BIT XOR TEST: FAIL *****");

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule
