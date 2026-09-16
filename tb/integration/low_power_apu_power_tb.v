`timescale 1ns/1ps

module low_power_apu_power_tb;

    reg         clk;
    reg         rst;
    reg         enable;
    reg  [2:0]  opcode;
    reg  [15:0] A;
    reg  [15:0] B;

    wire [31:0] result;
    wire [6:0]  flags;
    wire        valid;

    localparam ADD = 3'b000;
    localparam SUB = 3'b001;
    localparam MUL = 3'b010;
    localparam DIV = 3'b011;
    localparam AND_OP = 3'b100;
    localparam OR_OP  = 3'b101;
    localparam XOR_OP = 3'b110;
    localparam NOT_OP = 3'b111;

    low_power_apu dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .opcode(opcode),
        .A(A),
        .B(B),
        .result(result),
        .flags(flags),
        .valid(valid)
    );

    always #5 clk = ~clk;

    task execute;
        input [2:0]  op;
        input [15:0] a_in;
        input [15:0] b_in;
        begin
            @(negedge clk);
            opcode = op;
            A = a_in;
            B = b_in;
            enable = 1'b1;

            @(posedge clk);
            #1;

            enable = 1'b0;
        end
    endtask

    initial begin

        $dumpfile("sim/low_power.vcd");
        $dumpvars(0, low_power_apu_power_tb);

        clk    = 1'b0;
        rst    = 1'b1;
        enable = 1'b0;
        opcode = ADD;
        A      = 16'h0000;
        B      = 16'h0000;

        repeat (2) @(posedge clk);
        rst = 1'b0;

        // ADD workload
        execute(ADD, 16'h0001, 16'h0001);
        execute(ADD, 16'h00FF, 16'h0001);
        execute(ADD, 16'hFFFF, 16'h0001);
        execute(ADD, 16'hAAAA, 16'h5555);

        // SUB workload
        execute(SUB, 16'h0005, 16'h0003);
        execute(SUB, 16'h0003, 16'h0005);
        execute(SUB, 16'hFFFF, 16'h0001);
        execute(SUB, 16'hAAAA, 16'h5555);

        // MUL workload
        execute(MUL, 16'h0003, 16'h0007);
        execute(MUL, 16'h00FF, 16'h00FF);
        execute(MUL, 16'hFFFF, 16'hFFFF);
        execute(MUL, 16'hAAAA, 16'h5555);

        // DIV workload
        execute(DIV, 16'h0064, 16'h0004);
        execute(DIV, 16'hFFFF, 16'h0003);
        execute(DIV, 16'hAAAA, 16'h0011);
        execute(DIV, 16'h1234, 16'h0000);

        // Logic workload
        execute(AND_OP, 16'hAAAA, 16'h5555);
        execute(AND_OP, 16'hFFFF, 16'h0F0F);

        execute(OR_OP, 16'hAAAA, 16'h5555);
        execute(OR_OP, 16'h0000, 16'hFFFF);

        execute(XOR_OP, 16'hAAAA, 16'h5555);
        execute(XOR_OP, 16'hFFFF, 16'h0F0F);

        execute(NOT_OP, 16'hAAAA, 16'h0000);
        execute(NOT_OP, 16'h0000, 16'h0000);

        // Repeated mixed workload
        repeat (20) begin
            execute(ADD, 16'h1234, 16'h5678);
            execute(SUB, 16'hFFFF, 16'h1234);
            execute(MUL, 16'h0017, 16'h0023);
            execute(DIV, 16'hABCD, 16'h0011);
            execute(AND_OP, 16'hF0F0, 16'h0FF0);
            execute(OR_OP, 16'hAAAA, 16'h1111);
            execute(XOR_OP, 16'h5555, 16'hAAAA);
            execute(NOT_OP, 16'h3333, 16'h0000);
        end

        // Idle period
        repeat (20) @(posedge clk);

        $display("==============================================");
        $display(" LOW-POWER APU POWER WORKLOAD COMPLETE");
        $display("==============================================");

        $finish;
    end

endmodule
