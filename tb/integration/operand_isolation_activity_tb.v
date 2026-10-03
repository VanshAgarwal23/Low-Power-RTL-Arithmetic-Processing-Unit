`timescale 1ns/1ps

module operand_isolation_activity_tb();
    parameter WIDTH = 16;
    
    reg [WIDTH-1:0] a, b;
    reg add_en, sub_en, mul_en, logic_en;
    
    wire [WIDTH-1:0] add_a, add_b, sub_a, sub_b, mul_a, mul_b, logic_a, logic_b;
    
    integer errors = 0;

    operand_isolation #(.WIDTH(WIDTH)) dut (
        .a(a), .b(b),
        .add_en(add_en), .sub_en(sub_en), .mul_en(mul_en), .logic_en(logic_en),
        .add_a(add_a), .add_b(add_b), .sub_a(sub_a), .sub_b(sub_b),
        .mul_a(mul_a), .mul_b(mul_b), .logic_a(logic_a), .logic_b(logic_b)
    );

    task check_isolation;
        input [80*8:1] test_name;
        begin
            #1; // wait for combinational prop
            // If enable is 0, output must be 0. If 1, output must equal input.
            if ((add_en  ? (add_a !== a || add_b !== b) : (add_a !== 0 || add_b !== 0)) ||
                (sub_en  ? (sub_a !== a || sub_b !== b) : (sub_a !== 0 || sub_b !== 0)) ||
                (mul_en  ? (mul_a !== a || mul_b !== b) : (mul_a !== 0 || mul_b !== 0)) ||
                (logic_en? (logic_a!== a|| logic_b!== b): (logic_a!== 0|| logic_b!== 0))) begin
                $display("[FAIL] %s", test_name);
                errors = errors + 1;
            end else begin
                $display("[PASS] %s", test_name);
            end
        end
    endtask

    initial begin
        // Apply random noise to inputs
        a = 16'hAAAA; b = 16'h5555;
        
        // Test all disabled
        add_en = 0; sub_en = 0; mul_en = 0; logic_en = 0;
        check_isolation("All blocks disabled (Zero-forced)");

        // Test only ADD enabled
        add_en = 1; sub_en = 0; mul_en = 0; logic_en = 0;
        check_isolation("Only ADD enabled");

        // Test only MUL enabled with new inputs
        a = 16'hFFFF; b = 16'h1234;
        add_en = 0; sub_en = 0; mul_en = 1; logic_en = 0;
        check_isolation("Only MUL enabled");

        $display("--------------------------------------------------");
        if (errors == 0) $display("SUCCESS: Operand Isolation tests PASSED!");
        else $display("FAILED: Operand Isolation tests FAILED.");
        $display("--------------------------------------------------");
        $finish;
    end
endmodule
