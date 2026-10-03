`timescale 1ns/1ps

module low_power_apu_power_tb();
    parameter WIDTH = 16;
    
    reg clk, rst, enable;
    reg [2:0] opcode;
    reg [WIDTH-1:0] A, B;
    
    wire [2*WIDTH-1:0] result;
    wire [6:0] flags;
    wire valid;
    
    low_power_apu #(.WIDTH(WIDTH)) dut (
        .clk(clk), .rst(rst), .enable(enable), .opcode(opcode),
        .A(A), .B(B), .result(result), .flags(flags), .valid(valid)
    );

    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock

    integer i;

    initial begin
        // Generate Switching Activity File
        $dumpfile("power_activity.vcd");
        $dumpvars(0, low_power_apu_power_tb);

        // Reset
        rst = 1; enable = 0; opcode = 0; A = 0; B = 0;
        #20; rst = 0;

        $display("Starting Phase 1: Heavy Active Workload (1000 cycles)");
        enable = 1;
        for (i = 0; i < 1000; i = i + 1) begin
            @(negedge clk);
            opcode = $urandom % 8; // Random operation
            A = $urandom;
            B = $urandom;
        end

        $display("Starting Phase 2: Idle Mode with Noisy Inputs (1000 cycles)");
        $display("-> ICG should gate clock, Operand Isolation should force internal nets to 0.");
        enable = 0;
        for (i = 0; i < 1000; i = i + 1) begin
            @(negedge clk);
            opcode = $urandom % 8; // Inputs still toggle wildly
            A = $urandom;
            B = $urandom;
        end

        $display("Simulation complete. Analyze 'power_activity.vcd' for toggle rates.");
        $finish;
    end
endmodule
