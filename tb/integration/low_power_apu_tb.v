`timescale 1ns/1ps

module low_power_apu_tb;

    parameter WIDTH = 16;

    reg                 clk;
    reg                 rst;
    reg                 enable;
    reg [2:0]           opcode;
    reg [WIDTH-1:0]     A;
    reg [WIDTH-1:0]     B;

    wire [2*WIDTH-1:0] result;
    wire [6:0]         flags;
    wire               valid;

    reg [2*WIDTH-1:0] expected_result;
    reg [6:0]         expected_flags;

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_MUL = 3'b010;
    localparam OP_AND = 3'b100;
    localparam OP_OR  = 3'b101;
    localparam OP_XOR = 3'b110;
    localparam OP_NOT = 3'b111;


    // --------------------------------------------------
    // DUT
    // --------------------------------------------------

    low_power_apu #(
        .WIDTH(WIDTH)
    ) dut (
        .clk    (clk),
        .rst    (rst),
        .enable (enable),
        .opcode (opcode),
        .A      (A),
        .B      (B),
        .result (result),
        .flags  (flags),
        .valid  (valid)
    );


    // --------------------------------------------------
    // Clock
    // --------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // --------------------------------------------------
    // Expected result and flags
    // --------------------------------------------------

    task calculate_expected;

        input [WIDTH-1:0] A_in;
        input [WIDTH-1:0] B_in;
        input [2:0]       OP_in;

        reg [WIDTH-1:0] selected_result;
        reg [2*WIDTH-1:0] full_result;

        begin

            selected_result = 0;
            full_result = 0;
            expected_flags = 7'b0;

            case (OP_in)

                OP_ADD: begin

                    full_result = {1'b0, A_in} + {1'b0, B_in};

                    selected_result = full_result[WIDTH-1:0];

                    expected_flags[2] = full_result[WIDTH];

                    expected_flags[4] =
                        (~(A_in[WIDTH-1] ^ B_in[WIDTH-1])) &
                        (selected_result[WIDTH-1] ^ A_in[WIDTH-1]);

                end


                OP_SUB: begin

                    selected_result = A_in - B_in;

                    expected_flags[3] = (A_in < B_in);

                    expected_flags[4] =
                        (A_in[WIDTH-1] ^ B_in[WIDTH-1]) &
                        (selected_result[WIDTH-1] ^ A_in[WIDTH-1]);

                end


                OP_MUL: begin

                    full_result = A_in * B_in;

                end


                OP_AND:
                    selected_result = A_in & B_in;


                OP_OR:
                    selected_result = A_in | B_in;


                OP_XOR:
                    selected_result = A_in ^ B_in;


                OP_NOT:
                    selected_result = ~A_in;

            endcase


            if (OP_in == OP_MUL)
                full_result = A_in * B_in;
            else
                full_result = {{WIDTH{1'b0}}, selected_result};


            // Z
            expected_flags[0] = (full_result == 0);


            // N
            if (OP_in == OP_MUL)
                expected_flags[1] = full_result[2*WIDTH-1];
            else
                expected_flags[1] = selected_result[WIDTH-1];


            // P
            if (OP_in == OP_MUL)
                expected_flags[5] = ~(^full_result);
            else
                expected_flags[5] = ~(^selected_result);


            expected_result = full_result;

        end

    endtask


    // --------------------------------------------------
    // Execute and check operation
    // --------------------------------------------------

    task check_operation;

        input [WIDTH-1:0] A_in;
        input [WIDTH-1:0] B_in;
        input [2:0]       OP_in;
        input [255:0]     test_name;

        begin

            A = A_in;
            B = B_in;
            opcode = OP_in;
            enable = 1'b1;

            calculate_expected(A_in, B_in, OP_in);

            @(posedge clk);
            #1;

            total_tests = total_tests + 1;

            if ((result === expected_result) &&
                (flags === expected_flags) &&
                (valid === 1'b1)) begin

                passed_tests = passed_tests + 1;

                $display(
                    "[PASS] %-30s | A=%h B=%h | RESULT=%h | FLAGS=%07b",
                    test_name,
                    A,
                    B,
                    result,
                    flags
                );

            end
            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "[FAIL] %-30s | A=%h B=%h | Expected R=%h F=%07b | Got R=%h F=%07b V=%b",
                    test_name,
                    A,
                    B,
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
    // Main test
    // --------------------------------------------------

    initial begin

        total_tests = 0;
        passed_tests = 0;
        failed_tests = 0;

        rst = 1'b1;
        enable = 1'b0;
        A = 0;
        B = 0;
        opcode = OP_ADD;

        $dumpfile("sim/low_power_apu.vcd");
        $dumpvars(0, low_power_apu_tb);


        $display("");
        $display("==============================================");
        $display("        LOW-POWER APU VERIFICATION");
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
        // ADD
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


        // ==================================================
        // SUB
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


        // ==================================================
        // MUL
        // ==================================================

        check_operation(16'h0000, 16'h0000, OP_MUL,
                        "MUL ZERO x ZERO");

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


        // ==================================================
        // AND
        // ==================================================

        check_operation(16'h0000, 16'h0000, OP_AND,
                        "AND ZERO");

        check_operation(16'hFFFF, 16'hFFFF, OP_AND,
                        "AND MAX");

        check_operation(16'hAAAA, 16'h5555, OP_AND,
                        "AND PATTERN");

        check_operation(16'hF0F0, 16'h0FF0, OP_AND,
                        "AND OVERLAP");


        // ==================================================
        // OR
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
        // XOR
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
        // NOT
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


        // ==================================================
        // ENABLE / VALID
        // ==================================================

        A = 16'h1234;
        B = 16'h5678;
        opcode = OP_ADD;
        enable = 1'b0;

        @(posedge clk);
        #1;

        total_tests = total_tests + 1;

        if (valid === 1'b0) begin
            passed_tests = passed_tests + 1;
            $display("[PASS] ENABLE DISABLED             | VALID=0");
        end
        else begin
            failed_tests = failed_tests + 1;
            $display("[FAIL] ENABLE DISABLED             | VALID=%b",
                     valid);
        end


        // ==================================================
        // Final summary
        // ==================================================

        $display("");
        $display("==============================================");
        $display("        LOW-POWER APU TEST SUMMARY");
        $display("==============================================");
        $display("Total Tests : %0d", total_tests);
        $display("Passed      : %0d", passed_tests);
        $display("Failed      : %0d", failed_tests);
        $display("==============================================");

        if (failed_tests == 0)
            $display("***** LOW-POWER APU TEST: PASS *****");
        else
            $display("***** LOW-POWER APU TEST: FAIL *****");

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule
