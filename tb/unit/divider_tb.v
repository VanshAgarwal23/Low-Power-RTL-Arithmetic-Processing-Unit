`timescale 1ns/1ps

module divider_tb;

    parameter WIDTH = 16;

    reg  [WIDTH-1:0] test_dividend;
    reg  [WIDTH-1:0] test_divisor;

    wire [WIDTH-1:0] quotient;

    reg  [WIDTH-1:0] expected;

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    divider #(
        .WIDTH(WIDTH)
    ) dut (
        .dividend(test_dividend),
        .divisor(test_divisor),
        .quotient(quotient)
    );


    // --------------------------------------------------
    // Test task
    // --------------------------------------------------
    task check_div;
        input [WIDTH-1:0] dividend_in;
        input [WIDTH-1:0] divisor_in;
        input [255:0] test_name;

        begin
            test_dividend = dividend_in;
            test_divisor  = divisor_in;

            #1;

            if (test_divisor != 0)
                expected = test_dividend / test_divisor;
            else
                expected = {WIDTH{1'b0}};

            total_tests = total_tests + 1;

            if (quotient === expected) begin

                passed_tests = passed_tests + 1;

                $display(
                    "[PASS] %-28s | DIVIDEND=%5d DIVISOR=%5d | QUOTIENT=%5d",
                    test_name,
                    test_dividend,
                    test_divisor,
                    quotient
                );

            end
            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "[FAIL] %-28s | DIVIDEND=%5d DIVISOR=%5d | Expected=%5d | Got=%5d",
                    test_name,
                    test_dividend,
                    test_divisor,
                    expected,
                    quotient
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

        test_dividend = 0;
        test_divisor  = 0;

        $dumpfile("sim/divider.vcd");
        $dumpvars(0, divider_tb);

        $display("");
        $display("==============================================");
        $display("         16-BIT DIVIDER VERIFICATION");
        $display("==============================================");
        $display("");


        // --------------------------------------------------
        // Zero cases
        // --------------------------------------------------
        check_div(16'd0, 16'd0, "ZERO / ZERO");
        check_div(16'd0, 16'd1, "ZERO / ONE");
        check_div(16'd0, 16'd2, "ZERO / TWO");
        check_div(16'd0, 16'd100, "ZERO / 100");
        check_div(16'd0, 16'hFFFF, "ZERO / MAX");


        // --------------------------------------------------
        // Divide by zero
        // --------------------------------------------------
        check_div(16'd1,     16'd0, "ONE / ZERO");
        check_div(16'd2,     16'd0, "TWO / ZERO");
        check_div(16'd100,   16'd0, "100 / ZERO");
        check_div(16'h7FFF,  16'd0, "7FFF / ZERO");
        check_div(16'h8000,  16'd0, "8000 / ZERO");
        check_div(16'hFFFF,  16'd0, "MAX / ZERO");


        // --------------------------------------------------
        // Divide by one
        // --------------------------------------------------
        check_div(16'd1,     16'd1, "ONE / ONE");
        check_div(16'd10,    16'd1, "10 / ONE");
        check_div(16'd255,   16'd1, "255 / ONE");
        check_div(16'h7FFF,  16'd1, "7FFF / ONE");
        check_div(16'h8000,  16'd1, "8000 / ONE");
        check_div(16'hFFFF,  16'd1, "MAX / ONE");


        // --------------------------------------------------
        // Equal operands
        // --------------------------------------------------
        check_div(16'd2,     16'd2, "2 / 2");
        check_div(16'd10,    16'd10, "10 / 10");
        check_div(16'd255,   16'd255, "255 / 255");
        check_div(16'h7FFF,  16'h7FFF, "7FFF / 7FFF");
        check_div(16'h8000,  16'h8000, "8000 / 8000");
        check_div(16'hFFFF,  16'hFFFF, "MAX / MAX");


        // --------------------------------------------------
        // Exact divisions
        // --------------------------------------------------
        check_div(16'd10,    16'd2,     "10 / 2");
        check_div(16'd100,   16'd10,    "100 / 10");
        check_div(16'd100,   16'd4,     "100 / 4");
        check_div(16'd144,   16'd12,    "144 / 12");
        check_div(16'd256,   16'd16,    "256 / 16");
        check_div(16'd1024,  16'd32,    "1024 / 32");
        check_div(16'd4096,  16'd64,    "4096 / 64");
        check_div(16'd8192,  16'd128,   "8192 / 128");
        check_div(16'd16384, 16'd256,   "16384 / 256");


        // --------------------------------------------------
        // Divisions with remainders
        // --------------------------------------------------
        check_div(16'd5,     16'd2,     "5 / 2");
        check_div(16'd7,     16'd3,     "7 / 3");
        check_div(16'd10,    16'd3,     "10 / 3");
        check_div(16'd17,    16'd5,     "17 / 5");
        check_div(16'd99,    16'd10,    "99 / 10");
        check_div(16'd100,   16'd7,     "100 / 7");
        check_div(16'd255,   16'd16,    "255 / 16");
        check_div(16'd1000,  16'd33,    "1000 / 33");


        // --------------------------------------------------
        // Divisor greater than dividend
        // --------------------------------------------------
        check_div(16'd1,     16'd2,     "1 / 2");
        check_div(16'd2,     16'd3,     "2 / 3");
        check_div(16'd10,    16'd20,    "10 / 20");
        check_div(16'd100,   16'd101,   "100 / 101");
        check_div(16'd255,   16'd256,   "255 / 256");
        check_div(16'd4095,  16'd4096,  "4095 / 4096");


        // --------------------------------------------------
        // Maximum-value cases
        // --------------------------------------------------
        check_div(16'hFFFF, 16'd2,     "MAX / 2");
        check_div(16'hFFFF, 16'd3,     "MAX / 3");
        check_div(16'hFFFF, 16'd4,     "MAX / 4");
        check_div(16'hFFFF, 16'd10,    "MAX / 10");
        check_div(16'hFFFF, 16'h00FF,  "MAX / 255");
        check_div(16'hFFFF, 16'h0100,  "MAX / 256");
        check_div(16'hFFFF, 16'h8000,  "MAX / 8000");


        // --------------------------------------------------
        // Signed-boundary bit patterns
        // --------------------------------------------------
        check_div(16'h7FFF, 16'd2,     "7FFF / 2");
        check_div(16'h8000, 16'd2,     "8000 / 2");
        check_div(16'h8001, 16'd2,     "8001 / 2");
        check_div(16'hFFFE, 16'd2,     "FFFE / 2");
        check_div(16'hFFFF, 16'd2,     "FFFF / 2");


        // --------------------------------------------------
        // Power-of-two divisors
        // --------------------------------------------------
        check_div(16'd256,   16'd2,     "256 / 2");
        check_div(16'd256,   16'd4,     "256 / 4");
        check_div(16'd256,   16'd8,     "256 / 8");
        check_div(16'd256,   16'd16,    "256 / 16");
        check_div(16'd256,   16'd32,    "256 / 32");

        check_div(16'd4096,  16'd2,     "4096 / 2");
        check_div(16'd4096,  16'd4,     "4096 / 4");
        check_div(16'd4096,  16'd16,    "4096 / 16");
        check_div(16'd4096,  16'd64,    "4096 / 64");

        check_div(16'h8000,  16'h4000,  "8000 / 4000");
        check_div(16'h8000,  16'h2000,  "8000 / 2000");


        // --------------------------------------------------
        // Pattern tests
        // --------------------------------------------------
        check_div(16'hAAAA, 16'h0002, "AAAA / 2");
        check_div(16'h5555, 16'h0002, "5555 / 2");

        check_div(16'hFFFF, 16'h00FF, "FFFF / FF");
        check_div(16'hAAAA, 16'h00AA, "AAAA / AA");
        check_div(16'hCCCC, 16'h000C, "CCCC / C");
        check_div(16'hF0F0, 16'h0010, "F0F0 / 10");


        // --------------------------------------------------
        // Boundary around 8-bit transition
        // --------------------------------------------------
        check_div(16'h00FF, 16'd2,     "00FF / 2");
        check_div(16'h0100, 16'd2,     "0100 / 2");
        check_div(16'h0101, 16'd2,     "0101 / 2");

        check_div(16'h00FF, 16'h00FF, "00FF / 00FF");
        check_div(16'h0100, 16'h00FF, "0100 / 00FF");


        // --------------------------------------------------
        // Boundary around 12-bit transition
        // --------------------------------------------------
        check_div(16'h0FFF, 16'd2,     "0FFF / 2");
        check_div(16'h1000, 16'd2,     "1000 / 2");
        check_div(16'h1001, 16'd2,     "1001 / 2");


        // --------------------------------------------------
        // Randomized verification
        // --------------------------------------------------
        repeat (1000) begin
            check_div(
                $urandom_range(0, 16'hFFFF),
                $urandom_range(1, 16'hFFFF),
                "RANDOMIZED TEST"
            );
        end


        // --------------------------------------------------
        // Final summary
        // --------------------------------------------------
        $display("");
        $display("==============================================");
        $display("          DIVIDER TEST SUMMARY");
        $display("==============================================");
        $display("Total Tests : %0d", total_tests);
        $display("Passed      : %0d", passed_tests);
        $display("Failed      : %0d", failed_tests);
        $display("==============================================");

        if (failed_tests == 0) begin
            $display("***** 16-BIT DIVIDER TEST: PASS *****");
        end
        else begin
            $display("***** 16-BIT DIVIDER TEST: FAIL *****");
        end

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule
