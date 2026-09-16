`timescale 1ns/1ps

module subtractor_tb;

    parameter WIDTH = 16;

    reg  [WIDTH-1:0] test_a;
    reg  [WIDTH-1:0] test_b;

    wire [WIDTH-1:0] diff;
    wire             borrow;

    reg  [WIDTH:0] expected;
    reg            expected_borrow;

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    subtractor #(
        .WIDTH(WIDTH)
    ) dut (
        .a(test_a),
        .b(test_b),
        .diff(diff),
        .borrow(borrow)
    );

    // --------------------------------------------------
    // Test task
    // --------------------------------------------------
    task check_sub;
        input [WIDTH-1:0] a_in;
        input [WIDTH-1:0] b_in;
        input [255:0] test_name;

        begin
            test_a = a_in;
            test_b = b_in;

            #1;

            expected = {1'b0, test_a} - {1'b0, test_b};
            expected_borrow = (test_a < test_b);

            total_tests = total_tests + 1;

            if ((diff === expected[WIDTH-1:0]) &&
                (borrow === expected_borrow)) begin

                passed_tests = passed_tests + 1;

                $display(
                    "[PASS] %-25s | A=%5d B=%5d | DIFF=%5d BORROW=%1b",
                    test_name,
                    test_a,
                    test_b,
                    diff,
                    borrow
                );

            end
            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "[FAIL] %-25s | A=%5d B=%5d | Expected DIFF=%5d BORROW=%1b | Got DIFF=%5d BORROW=%1b",
                    test_name,
                    test_a,
                    test_b,
                    expected[WIDTH-1:0],
                    expected_borrow,
                    diff,
                    borrow
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

        test_a = 0;
        test_b = 0;

        $dumpfile("sim/subtractor.vcd");
        $dumpvars(0, subtractor_tb);

        $display("");
        $display("==============================================");
        $display("       16-BIT SUBTRACTOR VERIFICATION");
        $display("==============================================");
        $display("");

        // --------------------------------------------------
        // Basic cases
        // --------------------------------------------------
        check_sub(16'd0,     16'd0,     "ZERO - ZERO");
        check_sub(16'd1,     16'd0,     "ONE - ZERO");
        check_sub(16'd1,     16'd1,     "EQUAL VALUES");
        check_sub(16'd10,    16'd5,     "BASIC SUBTRACTION");
        check_sub(16'd5,     16'd10,    "BASIC BORROW");


        // --------------------------------------------------
        // Minimum / Maximum boundaries
        // --------------------------------------------------
        check_sub(16'h0000,  16'h0001,  "MIN - ONE");
        check_sub(16'h0001,  16'h0000,  "ONE - MIN");

        check_sub(16'hFFFF,  16'h0000,  "MAX - ZERO");
        check_sub(16'hFFFF,  16'hFFFF,  "MAX - MAX");

        check_sub(16'h0000,  16'hFFFF,  "ZERO - MAX");
        check_sub(16'hFFFF,  16'hFFFE,  "MAX - MAX-1");
        check_sub(16'hFFFE,  16'hFFFF,  "MAX-1 - MAX");


        // --------------------------------------------------
        // Borrow boundary cases
        // --------------------------------------------------
        check_sub(16'h0000, 16'h0001, "BORROW 0 - 1");
        check_sub(16'h0001, 16'h0002, "BORROW 1 - 2");
        check_sub(16'h0002, 16'h0001, "NO BORROW 2 - 1");

        check_sub(16'h00FF, 16'h0100, "BORROW BYTE BOUNDARY");
        check_sub(16'h0100, 16'h00FF, "NO BORROW BYTE BOUNDARY");

        check_sub(16'h0FFF, 16'h1000, "BORROW 12-BIT BOUNDARY");
        check_sub(16'h1000, 16'h0FFF, "NO BORROW 12-BIT BOUNDARY");

        check_sub(16'h7FFF, 16'h8000, "BORROW SIGN BOUNDARY");
        check_sub(16'h8000, 16'h7FFF, "NO BORROW SIGN BOUNDARY");


        // --------------------------------------------------
        // Signed arithmetic boundaries
        // --------------------------------------------------
        check_sub(16'h7FFF, 16'h0001, "SIGNED MAX - 1");
        check_sub(16'h8000, 16'h0001, "SIGNED MIN - 1");
        check_sub(16'h7FFF, 16'hFFFF, "SIGNED MAX - (-1)");
        check_sub(16'h8000, 16'hFFFF, "SIGNED MIN - (-1)");

        check_sub(16'hFFFF, 16'h0001, "-1 - 1");
        check_sub(16'h0001, 16'hFFFF, "1 - (-1)");


        // --------------------------------------------------
        // Pattern tests
        // --------------------------------------------------
        check_sub(16'hAAAA, 16'h5555, "AAAA - 5555");
        check_sub(16'h5555, 16'hAAAA, "5555 - AAAA");
        check_sub(16'hFFFF, 16'hAAAA, "FFFF - AAAA");
        check_sub(16'hAAAA, 16'hFFFF, "AAAA - FFFF");

        check_sub(16'hF0F0, 16'h0F0F, "F0F0 - 0F0F");
        check_sub(16'h0F0F, 16'hF0F0, "0F0F - F0F0");

        check_sub(16'hCCCC, 16'h3333, "CCCC - 3333");
        check_sub(16'h3333, 16'hCCCC, "3333 - CCCC");


        // --------------------------------------------------
        // Power-of-two boundary tests
        // --------------------------------------------------
        check_sub(16'h0002, 16'h0001, "2 - 1");
        check_sub(16'h0004, 16'h0002, "4 - 2");
        check_sub(16'h0008, 16'h0004, "8 - 4");
        check_sub(16'h0010, 16'h0008, "16 - 8");
        check_sub(16'h0100, 16'h0080, "256 - 128");
        check_sub(16'h1000, 16'h0800, "4096 - 2048");
        check_sub(16'h8000, 16'h4000, "32768 - 16384");


        // --------------------------------------------------
        // Randomized verification
        // --------------------------------------------------
        repeat (1000) begin
            check_sub(
                $urandom_range(0, 16'hFFFF),
                $urandom_range(0, 16'hFFFF),
                "RANDOMIZED TEST"
            );
        end


        // --------------------------------------------------
        // Final summary
        // --------------------------------------------------
        $display("");
        $display("==============================================");
        $display("        SUBTRACTOR TEST SUMMARY");
        $display("==============================================");
        $display("Total Tests : %0d", total_tests);
        $display("Passed      : %0d", passed_tests);
        $display("Failed      : %0d", failed_tests);
        $display("==============================================");

        if (failed_tests == 0) begin
            $display("***** 16-BIT SUBTRACTOR TEST: PASS *****");
        end
        else begin
            $display("***** 16-BIT SUBTRACTOR TEST: FAIL *****");
        end

        $display("==============================================");
        $display("");

        $finish;
    end

endmodule
