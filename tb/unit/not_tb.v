`timescale 1ns/1ps

module not_tb;

    parameter WIDTH = 16;

    reg  [WIDTH-1:0] a;
    reg  [WIDTH-1:0] b;
    reg  [2:0] opcode;

    wire [WIDTH-1:0] result;

    reg [WIDTH-1:0] expected;

    integer i;
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


    // --------------------------------------------------
    // Test task
    // --------------------------------------------------
    task check_not;
        input [WIDTH-1:0] a_in;
        input [255:0] test_name;

        begin
            a = a_in;
            b = 16'h0000;
            opcode = 3'b111;

            #1;

            expected = ~a_in;

            total_tests = total_tests + 1;

            if (result === expected) begin
                passed_tests = passed_tests + 1;

                // Display selected tests only
                if (total_tests <= 20) begin
                    $display(
                        "[PASS] %-25s | A=%h | RESULT=%h",
                        test_name, a, result
                    );
                end
            end
            else begin
                failed_tests = failed_tests + 1;

                $display(
                    "[FAIL] %-25s | A=%h | Expected=%h | Got=%h",
                    test_name, a, expected, result
                );
            end
        end
    endtask


    // --------------------------------------------------
    // Test sequence
    // --------------------------------------------------
    initial begin

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        a = 0;
        b = 0;
        opcode = 3'b111;

        $dumpfile("sim/not.vcd");
        $dumpvars(0, not_tb);

        $display("");
        $display("==============================================");
        $display("          16-BIT NOT VERIFICATION");
        $display("==============================================");
        $display("");


        // --------------------------------------------------
        // Directed boundary tests
        // --------------------------------------------------
        check_not(16'h0000, "ZERO");
        check_not(16'h0001, "ONE");
        check_not(16'h0002, "TWO");

        check_not(16'hFFFF, "MAX");
        check_not(16'hFFFE, "MAX-1");

        check_not(16'h7FFF, "SIGNED MAX");
        check_not(16'h8000, "SIGNED MIN");
        check_not(16'h8001, "SIGNED MIN+1");

        check_not(16'hAAAA, "AAAA PATTERN");
        check_not(16'h5555, "5555 PATTERN");

        check_not(16'hF0F0, "F0F0 PATTERN");
        check_not(16'h0F0F, "0F0F PATTERN");

        check_not(16'hCCCC, "CCCC PATTERN");
        check_not(16'h3333, "3333 PATTERN");

        check_not(16'h00FF, "LOW BYTE");
        check_not(16'hFF00, "HIGH BYTE");

        check_not(16'h0FFF, "LOW 12 BITS");
        check_not(16'hF000, "HIGH 4 BITS");


        // --------------------------------------------------
        // Exhaustive 16-bit verification
        // 0 through 65535
        // --------------------------------------------------
        $display("");
        $display("Starting exhaustive 16-bit NOT verification...");
        $display("Testing all 65536 possible input values.");
        $display("");

        for (i = 0; i <= 16'hFFFF; i = i + 1) begin
            check_not(i[WIDTH-1:0], "EXHAUSTIVE TEST");
        end


        // --------------------------------------------------
        // Final summary
        // --------------------------------------------------
        $display("");
        $display("==============================================");
        $display("             NOT TEST SUMMARY");
        $display("==============================================");
        $display("Total Tests : %0d", total_tests);
        $display("Passed      : %0d", passed_tests);
        $display("Failed      : %0d", failed_tests);
        $display("==============================================");

        if (failed_tests == 0)
            $display("***** 16-BIT NOT TEST: PASS *****");
        else
            $display("***** 16-BIT NOT TEST: FAIL *****");

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule
