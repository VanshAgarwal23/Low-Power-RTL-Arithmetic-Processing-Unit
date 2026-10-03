`timescale 1ns/1ps

module low_power_apu_tb();
    parameter WIDTH = 16;

    reg clk, rst, enable;
    reg [2:0] opcode;
    reg [WIDTH-1:0] A, B;

    wire [2*WIDTH-1:0] result;
    wire [6:0] flags;
    wire valid;

    integer errors = 0;
    integer tests  = 0;

    // Instantiate APU
    low_power_apu #(.WIDTH(WIDTH)) dut (
        .clk(clk), .rst(rst), .enable(enable), .opcode(opcode),
        .A(A), .B(B), .result(result), .flags(flags), .valid(valid)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Self-checking Task
    task check_out;
        input [2*WIDTH-1:0] exp_res;
        input exp_valid;
        input [80*8:1] test_name;
        begin
            tests = tests + 1;
            @(negedge clk); // Evaluate after the clock edge
            if (result !== exp_res || valid !== exp_valid) begin
                $display("[FAIL] %s | Exp: Res=%h Val=%b | Got: Res=%h Val=%b", 
                         test_name, exp_res, exp_valid, result, valid);
                errors = errors + 1;
            end else begin
                $display("[PASS] %s", test_name);
            end
        end
    endtask

    initial begin
        $dumpfile("apu_func.vcd");
        $dumpvars(0, low_power_apu_tb);

        // 1. Reset Test
        rst = 1; enable = 0; opcode = 0; A = 0; B = 0;
        @(negedge clk); rst = 0;
        check_out(32'h0, 1'b0, "Reset Behavior");

        // 2. ADD Tests
        enable = 1; opcode = 3'b000; A = 16'h0005; B = 16'h0003;
        check_out(32'h0000_0008, 1'b1, "ADD: 5 + 3");
        
        A = 16'hFFFF; B = 16'h0001; // Overflow/Carry test
        check_out(32'h0000_0000, 1'b1, "ADD: FFFF + 1 (Carry)");

        // 3. SUB Tests
        opcode = 3'b001; A = 16'h0005; B = 16'h0003;
        check_out(32'h0000_0002, 1'b1, "SUB: 5 - 3");
        
        A = 16'h0003; B = 16'h0005; // Borrow/Negative test
        check_out(32'h0000_FFFE, 1'b1, "SUB: 3 - 5 (Borrow)");

        // 4. MUL Tests
        opcode = 3'b010; A = 16'h0010; B = 16'h0010;
        check_out(32'h0000_0100, 1'b1, "MUL: 16 * 16");
        
        A = 16'hFFFF; B = 16'hFFFF; // Max multiplication
        check_out(32'hFFFE_0001, 1'b1, "MUL: FFFF * FFFF");

        // 5. Logic Tests (AND, OR, XOR, NOT)
        opcode = 3'b100; A = 16'hAAAA; B = 16'h5555;
        check_out(32'h0000_0000, 1'b1, "AND: AAAA & 5555");

        opcode = 3'b101;
        check_out(32'h0000_FFFF, 1'b1, "OR : AAAA | 5555");

        opcode = 3'b110;
        check_out(32'h0000_FFFF, 1'b1, "XOR: AAAA ^ 5555");

        opcode = 3'b111; A = 16'h00FF;
        check_out(32'h0000_FF00, 1'b1, "NOT: ~00FF");

        // 6. ICG / Clock Gating HOLD Test
        // Setup a state
        enable = 1; opcode = 3'b000; A = 16'h0010; B = 16'h0020;
        @(negedge clk);
        // Now disable the module, but change inputs wildly
        enable = 0; opcode = 3'b010; A = 16'hFFFF; B = 16'hFFFF;
        // The output SHOULD remain the old ADD result, and valid should drop to 0
        check_out(32'h0000_0030, 1'b0, "ICG HOLD: Enable=0 ignores new inputs");

        // 7. Re-enable Test
        enable = 1; // Now it should compute the MUL from the current inputs
        check_out(32'hFFFE_0001, 1'b1, "ICG RECOVER: Resumes computation");

        $display("--------------------------------------------------");
        if (errors == 0)
            $display("SUCCESS: All %0d tests PASSED!", tests);
        else
            $display("FAILED: %0d out of %0d tests FAILED.", errors, tests);
        $display("--------------------------------------------------");
        $finish;
    end
endmodule
