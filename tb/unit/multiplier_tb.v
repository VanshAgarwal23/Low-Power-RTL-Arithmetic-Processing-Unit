`timescale 1ns/1ps

module multiplier_tb;

    parameter WIDTH = 16;

    reg  [WIDTH-1:0] test_a;
    reg  [WIDTH-1:0] test_b;

    wire [(2*WIDTH)-1:0] product;

    reg [(2*WIDTH)-1:0] expected;

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    multiplier #(
        .WIDTH(WIDTH)
    ) dut (
        .a(test_a),
        .b(test_b),
        .product(product)
    );


    // --------------------------------------------------
    // Test task
    // --------------------------------------------------
    task check_mul;
        input [WIDTH-1:0] a_in;
        input [WIDTH-1:0] b_in;
        input [255:0] test_name;

        begin
            test_a = a_in;
            test_b = b_in;

            #1;

            expected = test_a * test_b;

            total_tests = total_tests + 1;

            if (product === expected) begin

                passed_tests = passed_tests + 1;

                $display(
                    "[PASS] %-25s | A=%5d B=%5d | PRODUCT=%10d",
                    test_name,
                    test_a,
                    test_b,
                    product
                );

            end
            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "[FAIL] %-25s | A=%5d B=%5d | Expected=%10d | Got=%10d",
                    test_name,
                    test_a,
                    test_b,
                    expected,
                    product
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

        $dumpfile("sim/multiplier.vcd");
        $dumpvars(0, multiplier_tb);

        $display("");
        $display("==============================================");
        $display("       16-BIT MULTIPLIER VERIFICATION");
        $display("==============================================");
        $display("");


        // --------------------------------------------------
        // Zero cases
        // --------------------------------------------------
        check_mul(16'd0,     16'd0,     "ZERO x ZERO");
        check_mul(16'd0,     16'd1,     "ZERO x ONE");
        check_mul(16'd0,     16'd100,   "ZERO x 100");
        check_mul(16'd0,     16'hFFFF,  "ZERO x MAX");

        check_mul(16'd1,     16'd0,     "ONE x ZERO");
        check_mul(16'hFFFF,  16'd0,     "MAX x ZERO");


        // --------------------------------------------------
        // One cases
        // --------------------------------------------------
        check_mul(16'd1,     16'd1,     "ONE x ONE");
        check_mul(16'd1,     16'd2,     "ONE x TWO");
        check_mul(16'd1,     16'hFFFF,  "ONE x MAX");

        check_mul(16'hFFFF,  16'd1,     "MAX x ONE");


        // --------------------------------------------------
        // Small values
        // --------------------------------------------------
        check_mul(16'd2,     16'd2,     "2 x 2");
        check_mul(16'd3,     16'd3,     "3 x 3");
        check_mul(16'd5,     16'd7,     "5 x 7");
        check_mul(16'd10,    16'd10,    "10 x 10");
        check_mul(16'd100,   16'd100,   "100 x 100");
        check_mul(16'd255,   16'd255,   "255 x 255");
        check_mul(16'd256,   16'd256,   "256 x 256");


        // --------------------------------------------------
        // Maximum-value cases
        // --------------------------------------------------
        check_mul(16'hFFFF,  16'hFFFF,  "MAX x MAX");
        check_mul(16'hFFFF,  16'hFFFE,  "MAX x MAX-1");
        check_mul(16'hFFFE,  16'hFFFF,  "MAX-1 x MAX");


        // --------------------------------------------------
        // Full 32-bit result boundary
        // --------------------------------------------------
        check_mul(16'h8000, 16'h8000, "8000 x 8000");
        check_mul(16'hFFFF, 16'h8000, "FFFF x 8000");
        check_mul(16'h8000, 16'hFFFF, "8000 x FFFF");

        check_mul(16'hFFFF, 16'h0002, "FFFF x 2");
        check_mul(16'h8000, 16'h0002, "8000 x 2");


        // --------------------------------------------------
        // Power-of-two cases
        // --------------------------------------------------
        check_mul(16'd2,     16'd4,     "2 x 4");
        check_mul(16'd4,     16'd8,     "4 x 8");
        check_mul(16'd8,     16'd16,    "8 x 16");
        check_mul(16'd16,    16'd32,    "16 x 32");

        check_mul(16'd256,   16'd256,   "256 x 256");
        check_mul(16'd1024,  16'd1024,  "1024 x 1024");
        check_mul(16'd4096,  16'd8,     "4096 x 8");
        check_mul(16'd8192,  16'd4,     "8192 x 4");
        check_mul(16'd16384, 16'd2,     "16384 x 2");


        // --------------------------------------------------
        // Pattern tests
        // --------------------------------------------------
        check_mul(16'hAAAA, 16'h5555, "AAAA x 5555");
        check_mul(16'h5555, 16'hAAAA, "5555 x AAAA");

        check_mul(16'hFFFF, 16'hAAAA, "FFFF x AAAA");
        check_mul(16'hAAAA, 16'hFFFF, "AAAA x FFFF");

        check_mul(16'hCCCC, 16'h3333, "CCCC x 3333");
        check_mul(16'h3333, 16'hCCCC, "3333 x CCCC");

        check_mul(16'hF0F0, 16'h0F0F, "F0F0 x 0F0F");
        check_mul(16'h0F0F, 16'hF0F0, "0F0F x F0F0");


        // --------------------------------------------------
        // Boundary around 8-bit transition
        // --------------------------------------------------
        check_mul(16'h00FF, 16'h00FF, "00FF x 00FF");
        check_mul(16'h0100, 16'h0100, "0100 x 0100");
        check_mul(16'h00FF, 16'h0100, "00FF x 0100");
        check_mul(16'h0100, 16'h00FF, "0100 x 00FF");


        // --------------------------------------------------
        // Boundary around 12-bit transition
        // --------------------------------------------------
        check_mul(16'h0FFF, 16'h0FFF, "0FFF x 0FFF");
        check_mul(16'h1000, 16'h1000, "1000 x 1000");
        check_mul(16'h0FFF, 16'h1000, "0FFF x 1000");
        check_mul(16'h1000, 16'h0FFF, "1000 x 0FFF");


        // --------------------------------------------------
        // Randomized verification
        // --------------------------------------------------
        repeat (1000) begin
            check_mul(
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
        $display("        MULTIPLIER TEST SUMMARY");
        $display("==============================================");
        $display("Total Tests : %0d", total_tests);
        $display("Passed      : %0d", passed_tests);
        $display("Failed      : %0d", failed_tests);
        $display("==============================================");

        if (failed_tests == 0) begin
            $display("***** 16-BIT MULTIPLIER TEST: PASS *****");
        end
        else begin
            $display("***** 16-BIT MULTIPLIER TEST: FAIL *****");
        end

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule
