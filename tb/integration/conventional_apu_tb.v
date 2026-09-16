`timescale 1ns/1ps

module conventional_apu_tb;

    parameter WIDTH = 16;

    // --------------------------------------------------
    // DUT inputs
    // --------------------------------------------------
    reg                  clk;
    reg                  rst;
    reg                  enable;
    reg  [WIDTH-1:0]     a;
    reg  [WIDTH-1:0]     b;
    reg  [2:0]           opcode;

    // --------------------------------------------------
    // DUT outputs
    // --------------------------------------------------
    wire [(2*WIDTH)-1:0] result;
    wire [6:0]           flags;
    wire                 valid;

    // --------------------------------------------------
    // Expected values
    // --------------------------------------------------
    reg [(2*WIDTH)-1:0] expected_result;
    reg [6:0]           expected_flags;

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    // --------------------------------------------------
    // Opcode definitions
    // --------------------------------------------------
    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_MUL = 3'b010;
    localparam OP_DIV = 3'b011;
    localparam OP_AND = 3'b100;
    localparam OP_OR  = 3'b101;
    localparam OP_XOR = 3'b110;
    localparam OP_NOT = 3'b111;
    // --------------------------------------------------
    // DUT
    // --------------------------------------------------
    
    // Clock generation
    conventional_apu #(
        .WIDTH(WIDTH)
    ) dut (
        .clk    (clk),
        .rst    (rst),
        .enable (enable),
        .A      (a),
        .B      (b),
        .opcode (opcode),
        .result (result),
        .flags  (flags),
        .valid  (valid)
    );    // --------------------------------------------------
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // --------------------------------------------------
    // Calculate expected flags
    //
    // flags:
    // bit 0 = Z
    // bit 1 = N
    // bit 2 = C
    // bit 3 = B
    // bit 4 = V
    // bit 5 = P
    // bit 6 = D
    // --------------------------------------------------
    task calculate_expected;
        input  [WIDTH-1:0]     a_in;
        input  [WIDTH-1:0]     b_in;
        input  [2:0]           op_in;

        reg [WIDTH-1:0]        selected_result;
        reg [2*WIDTH-1:0]      full_result;
        reg                    carry_expected;
        reg                    borrow_expected;
        reg                    overflow_expected;
        reg                    divide_zero_expected;
        reg                    negative_expected;
        reg                    parity_expected;

        begin

            full_result       = 0;
            selected_result  = 0;
            carry_expected   = 0;
            borrow_expected  = 0;
            overflow_expected = 0;
            divide_zero_expected = 0;

            case (op_in)

                OP_ADD: begin
                    full_result = {1'b0, a_in} + {1'b0, b_in};

                    selected_result = full_result[WIDTH-1:0];

                    carry_expected = full_result[WIDTH];

                    overflow_expected =
                        (~(a_in[WIDTH-1] ^ b_in[WIDTH-1])) &
                        (selected_result[WIDTH-1] ^ a_in[WIDTH-1]);
                end

                OP_SUB: begin
                    selected_result = a_in - b_in;

                    borrow_expected = (a_in < b_in);

                    overflow_expected =
                        (a_in[WIDTH-1] ^ b_in[WIDTH-1]) &
                        (selected_result[WIDTH-1] ^ a_in[WIDTH-1]);
                end

                OP_MUL: begin
                    full_result = a_in * b_in;
                end

                OP_DIV: begin
                    if (b_in != 0) begin
                        selected_result = a_in / b_in;
                    end
                    else begin
                        selected_result = 0;
                        divide_zero_expected = 1;
                    end
                end

                OP_AND: begin
                    selected_result = a_in & b_in;
                end

                OP_OR: begin
                    selected_result = a_in | b_in;
                end

                OP_XOR: begin
                    selected_result = a_in ^ b_in;
                end

                OP_NOT: begin
                    selected_result = ~a_in;
                end

            endcase


            // --------------------------------------------------
            // Construct expected 32-bit result
            // --------------------------------------------------
            if (op_in == OP_MUL)
                full_result = a_in * b_in;
            else
                full_result = {{WIDTH{1'b0}}, selected_result};


            // --------------------------------------------------
            // Z flag
            // --------------------------------------------------
            if (full_result == 0)
                expected_flags[0] = 1'b1;
            else
                expected_flags[0] = 1'b0;


            // --------------------------------------------------
            // N flag
            // --------------------------------------------------
            if (op_in == OP_MUL)
                negative_expected = full_result[(2*WIDTH)-1];
            else
                negative_expected = selected_result[WIDTH-1];

            expected_flags[1] = negative_expected;


            // --------------------------------------------------
            // Carry
            // --------------------------------------------------
            expected_flags[2] = carry_expected;


            // --------------------------------------------------
            // Borrow
            // --------------------------------------------------
            expected_flags[3] = borrow_expected;


            // --------------------------------------------------
            // Overflow
            // --------------------------------------------------
            expected_flags[4] = overflow_expected;


            // --------------------------------------------------
            // Even parity
            // --------------------------------------------------
            if (op_in == OP_MUL)
                parity_expected = ~(^full_result);
            else
                parity_expected = ~(^selected_result);

            expected_flags[5] = parity_expected;


            // --------------------------------------------------
            // Divide-by-zero
            // --------------------------------------------------
            expected_flags[6] = divide_zero_expected;


            expected_result = full_result;

        end
    endtask


    // --------------------------------------------------
    // Execute one APU operation
    // --------------------------------------------------
    task check_operation;
        input [WIDTH-1:0] a_in;
        input [WIDTH-1:0] b_in;
        input [2:0]       op_in;
        input [255:0]     test_name;

        begin

            a      = a_in;
            b      = b_in;
            opcode = op_in;
            enable = 1'b1;

            calculate_expected(a_in, b_in, op_in);

            // Wait for rising clock edge
            @(posedge clk);

            #1;

            total_tests = total_tests + 1;

            if ((result === expected_result) &&
                (flags === expected_flags) &&
                (valid === 1'b1)) begin

                passed_tests = passed_tests + 1;

                $display(
                    "[PASS] %-28s | A=%h B=%h | RESULT=%h | FLAGS=%07b",
                    test_name,
                    a,
                    b,
                    result,
                    flags
                );

            end
            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "[FAIL] %-28s | A=%h B=%h | Expected R=%h F=%07b | Got R=%h F=%07b V=%b",
                    test_name,
                    a,
                    b,
                    expected_result,
                    expected_flags,
                    result,
                    flags,
                    valid
                );

            end

            enable = 1'b0;

        end
    endtask


    // --------------------------------------------------
    // Main test sequence
    // --------------------------------------------------
    initial begin

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        rst    = 1'b1;
        enable = 1'b0;
        a      = 0;
        b      = 0;
        opcode = OP_ADD;

        $dumpfile("sim/conventional_apu.vcd");
        $dumpvars(0, conventional_apu_tb);

        $display("");
        $display("==============================================");
        $display("       CONVENTIONAL APU INTEGRATION TEST");
        $display("==============================================");
        $display("");

        // --------------------------------------------------
        // Reset
        // --------------------------------------------------
        @(posedge clk);
        #1;

        rst = 1'b0;

        $display("[INFO] Reset completed.");
        $display("");


        // ==================================================
        // ADD TESTS
        // ==================================================

        check_operation(16'h0000, 16'h0000, OP_ADD,
                        "ADD ZERO + ZERO");

        check_operation(16'h0001, 16'h0001, OP_ADD,
                        "ADD ONE + ONE");

        check_operation(16'hFFFF, 16'h0001, OP_ADD,
                        "ADD MAX + ONE");

        check_operation(16'hFFFF, 16'hFFFF, OP_ADD,
                        "ADD MAX + MAX");

        check_operation(16'h7FFF, 16'h0001, OP_ADD,
                        "ADD SIGNED POS OVERFLOW");

        check_operation(16'h8000, 16'h8000, OP_ADD,
                        "ADD SIGNED NEG OVERFLOW");

        check_operation(16'hAAAA, 16'h5555, OP_ADD,
                        "ADD PATTERN");

        check_operation(16'h1234, 16'h5678, OP_ADD,
                        "ADD NORMAL");


        // ==================================================
        // SUB TESTS
        // ==================================================

        check_operation(16'h0000, 16'h0000, OP_SUB,
                        "SUB ZERO - ZERO");

        check_operation(16'h0005, 16'h0003, OP_SUB,
                        "SUB NORMAL");

        check_operation(16'h0003, 16'h0005, OP_SUB,
                        "SUB BORROW");

        check_operation(16'h0000, 16'h0001, OP_SUB,
                        "SUB ZERO - ONE");

        check_operation(16'hFFFF, 16'h0001, OP_SUB,
                        "SUB MAX - ONE");

        check_operation(16'h7FFF, 16'hFFFF, OP_SUB,
                        "SUB POS - NEG OVERFLOW");

        check_operation(16'h8000, 16'h0001, OP_SUB,
                        "SUB NEG - POS OVERFLOW");

        check_operation(16'hAAAA, 16'h5555, OP_SUB,
                        "SUB PATTERN");


        // ==================================================
        // MUL TESTS
        // ==================================================

        check_operation(16'h0000, 16'h0000, OP_MUL,
                        "MUL ZERO x ZERO");

        check_operation(16'h0000, 16'hFFFF, OP_MUL,
                        "MUL ZERO x MAX");

        check_operation(16'h0001, 16'h0001, OP_MUL,
                        "MUL ONE x ONE");

        check_operation(16'h0002, 16'h0003, OP_MUL,
                        "MUL SMALL");

        check_operation(16'h00FF, 16'h00FF, OP_MUL,
                        "MUL BYTE MAX");

        check_operation(16'h8000, 16'h0002, OP_MUL,
                        "MUL SIGN BOUNDARY");

        check_operation(16'hFFFF, 16'hFFFF, OP_MUL,
                        "MUL MAX x MAX");

        check_operation(16'hAAAA, 16'h5555, OP_MUL,
                        "MUL PATTERN");


        // ==================================================
        // DIV TESTS
        // ==================================================

        check_operation(16'h0000, 16'h0000, OP_DIV,
                        "DIV ZERO / ZERO");

        check_operation(16'h0000, 16'h0001, OP_DIV,
                        "DIV ZERO / ONE");

        check_operation(16'h0001, 16'h0001, OP_DIV,
                        "DIV ONE / ONE");

        check_operation(16'h000A, 16'h0002, OP_DIV,
                        "DIV EXACT");

        check_operation(16'h0007, 16'h0003, OP_DIV,
                        "DIV REMAINDER");

        check_operation(16'h0003, 16'h0005, OP_DIV,
                        "DIV DIVISOR GREATER");

        check_operation(16'hFFFF, 16'h0002, OP_DIV,
                        "DIV MAX / TWO");

        check_operation(16'hFFFF, 16'h0000, OP_DIV,
                        "DIVIDE BY ZERO");


        // ==================================================
        // AND TESTS
        // ==================================================

        check_operation(16'h0000, 16'h0000, OP_AND,
                        "AND ZERO");

        check_operation(16'hFFFF, 16'hFFFF, OP_AND,
                        "AND MAX");

        check_operation(16'hFFFF, 16'h0000, OP_AND,
                        "AND MASK");

        check_operation(16'hAAAA, 16'h5555, OP_AND,
                        "AND PATTERN");

        check_operation(16'hF0F0, 16'h0FF0, OP_AND,
                        "AND OVERLAP");


        // ==================================================
        // OR TESTS
        // ==================================================

        check_operation(16'h0000, 16'h0000, OP_OR,
                        "OR ZERO");

        check_operation(16'hFFFF, 16'h0000, OP_OR,
                        "OR MAX");

        check_operation(16'hAAAA, 16'h5555, OP_OR,
                        "OR PATTERN");

        check_operation(16'hF0F0, 16'h0FF0, OP_OR,
                        "OR OVERLAP");


        // ==================================================
        // XOR TESTS
        // ==================================================

        check_operation(16'h0000, 16'h0000, OP_XOR,
                        "XOR ZERO");

        check_operation(16'hFFFF, 16'hFFFF, OP_XOR,
                        "XOR SAME");

        check_operation(16'hFFFF, 16'h0000, OP_XOR,
                        "XOR MASK");

        check_operation(16'hAAAA, 16'h5555, OP_XOR,
                        "XOR PATTERN");

        check_operation(16'hF0F0, 16'h0FF0, OP_XOR,
                        "XOR OVERLAP");


        // ==================================================
        // NOT TESTS
        // ==================================================

        check_operation(16'h0000, 16'h0000, OP_NOT,
                        "NOT ZERO");

        check_operation(16'hFFFF, 16'h0000, OP_NOT,
                        "NOT MAX");

        check_operation(16'hAAAA, 16'h0000, OP_NOT,
                        "NOT AAAA");

        check_operation(16'h5555, 16'h0000, OP_NOT,
                        "NOT 5555");

        check_operation(16'h8000, 16'h0000, OP_NOT,
                        "NOT SIGN BIT");

        check_operation(16'h7FFF, 16'h0000, OP_NOT,
                        "NOT SIGN BOUNDARY");


        // ==================================================
        // ENABLE / VALID TEST
        // ==================================================

        a      = 16'h1234;
        b      = 16'h5678;
        opcode = OP_ADD;
        enable = 1'b0;

        @(posedge clk);
        #1;

        total_tests = total_tests + 1;

        if (valid === 1'b0) begin
            passed_tests = passed_tests + 1;
            $display("[PASS] ENABLE DISABLED          | VALID=0");
        end
        else begin
            failed_tests = failed_tests + 1;
            $display("[FAIL] ENABLE DISABLED          | Expected VALID=0 Got=%b",
                     valid);
        end


        // ==================================================
        // Final summary
        // ==================================================

        $display("");
        $display("==============================================");
        $display("       CONVENTIONAL APU TEST SUMMARY");
        $display("==============================================");
        $display("Total Tests : %0d", total_tests);
        $display("Passed      : %0d", passed_tests);
        $display("Failed      : %0d", failed_tests);
        $display("==============================================");

        if (failed_tests == 0)
            $display("***** CONVENTIONAL APU TEST: PASS *****");
        else
            $display("***** CONVENTIONAL APU TEST: FAIL *****");

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule
