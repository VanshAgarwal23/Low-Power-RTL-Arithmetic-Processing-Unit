`timescale 1ns/1ps

module adder_tb;

    parameter WIDTH = 16;

    reg  [WIDTH-1:0] a;
    reg  [WIDTH-1:0] b;

    wire [WIDTH-1:0] sum;
    wire             carry;

    integer pass_count;
    integer fail_count;
    integer i;

    reg [WIDTH:0] expected;

    /*
     * Device Under Test
     */
    adder #(
        .WIDTH(WIDTH)
    ) dut (
        .a     (a),
        .b     (b),
        .sum   (sum),
        .carry (carry)
    );

    /*
     * Test task
     */
    task check_add;
        input [WIDTH-1:0] test_a;
        input [WIDTH-1:0] test_b;
        input [255:0]     test_name;

        begin

            a = test_a;
            b = test_b;

            #1;

            expected = {1'b0, test_a} + {1'b0, test_b};

            if ((sum === expected[WIDTH-1:0]) &&
                (carry === expected[WIDTH])) begin

                $display(
                    "[PASS] %-30s | A=%5d B=%5d | SUM=%5d C=%b",
                    test_name,
                    test_a,
                    test_b,
                    sum,
                    carry
                );

                pass_count = pass_count + 1;

            end
            else begin

                $display(
                    "[FAIL] %-30s | A=%5d B=%5d | Expected SUM=%5d C=%b | Got SUM=%5d C=%b",
                    test_name,
                    test_a,
                    test_b,
                    expected[WIDTH-1:0],
                    expected[WIDTH],
                    sum,
                    carry
                );

                fail_count = fail_count + 1;

            end

        end
    endtask

    /*
     * Main test sequence
     */
    initial begin

        pass_count = 0;
        fail_count = 0;

        a = 0;
        b = 0;

        $display("");
        $display("==============================================");
        $display("       16-BIT ADDER TESTBENCH");
        $display("==============================================");
        $display("");

        /*
         * ==========================================
         * ZERO / BASIC CASES
         * ==========================================
         */

        check_add(16'd0, 16'd0, "ZERO + ZERO");

        check_add(16'd0, 16'd1, "ZERO + ONE");

        check_add(16'd1, 16'd0, "ONE + ZERO");

        check_add(16'd1, 16'd1, "ONE + ONE");

        check_add(16'd10, 16'd20, "10 + 20");

        /*
         * ==========================================
         * LOWER BOUNDARY CASES
         * ==========================================
         */

        check_add(16'd0, 16'd65535, "ZERO + MAX");

        check_add(16'd65535, 16'd0, "MAX + ZERO");

        check_add(16'd0, 16'd32768, "ZERO + MSB");

        check_add(16'd32768, 16'd0, "MSB + ZERO");

        /*
         * ==========================================
         * CARRY CASES
         * ==========================================
         */

        check_add(16'd65535, 16'd1, "MAX + ONE");

        check_add(16'd65535, 16'd65535, "MAX + MAX");

        check_add(16'd32768, 16'd32768, "MSB + MSB");

        check_add(16'd32767, 16'd1, "MAX_SIGNED + ONE");

        check_add(16'd32767, 16'd32767, "MAX_SIGNED + MAX_SIGNED");

        check_add(16'd32768, 16'd32767, "MSB + MAX_SIGNED");

        /*
         * ==========================================
         * ALTERNATING BIT PATTERNS
         * ==========================================
         */

        check_add(16'hAAAA, 16'h5555, "AAAA + 5555");

        check_add(16'h5555, 16'hAAAA, "5555 + AAAA");

        check_add(16'hAAAA, 16'hAAAA, "AAAA + AAAA");

        check_add(16'h5555, 16'h5555, "5555 + 5555");

        check_add(16'hFFFF, 16'h0001, "FFFF + 0001");

        check_add(16'hFFFF, 16'hFFFF, "FFFF + FFFF");

        /*
         * ==========================================
         * POWER-OF-TWO CASES
         * ==========================================
         */

        check_add(16'h0001, 16'h0002, "1 + 2");

        check_add(16'h0002, 16'h0004, "2 + 4");

        check_add(16'h0004, 16'h0008, "4 + 8");

        check_add(16'h0008, 16'h0010, "8 + 16");

        check_add(16'h0010, 16'h0020, "16 + 32");

        check_add(16'h0080, 16'h0100, "128 + 256");

        check_add(16'h4000, 16'h4000, "16384 + 16384");

        check_add(16'h8000, 16'h8000, "32768 + 32768");

        /*
         * ==========================================
         * CARRY BOUNDARIES
         * ==========================================
         */

        check_add(16'h000F, 16'h0001, "15 + 1");

        check_add(16'h00FF, 16'h0001, "255 + 1");

        check_add(16'h0FFF, 16'h0001, "4095 + 1");

        check_add(16'h7FFF, 16'h0001, "32767 + 1");

        check_add(16'hFFFE, 16'h0001, "65534 + 1");

        check_add(16'hFFFE, 16'h0002, "65534 + 2");

        /*
         * ==========================================
         * RANDOMIZED / DETERMINISTIC CASES
         * ==========================================
         *
         * The deterministic seed allows the same
         * test set to be reproduced.
         */

        $display("");
        $display("----------------------------------------------");
        $display("Starting randomized verification...");
        $display("----------------------------------------------");

        for (i = 0; i < 1000; i = i + 1) begin

            check_add(
                $urandom,
                $urandom,
                "RANDOMIZED TEST"
            );

        end

        /*
         * ==========================================
         * FINAL SUMMARY
         * ==========================================
         */

        $display("");
        $display("==============================================");
        $display("          ADDER TEST SUMMARY");
        $display("==============================================");
        $display("Total Tests : %0d", pass_count + fail_count);
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0) begin
            $display("***** 16-BIT ADDER TEST: PASS *****");
        end
        else begin
            $display("***** 16-BIT ADDER TEST: FAIL *****");
        end

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule
