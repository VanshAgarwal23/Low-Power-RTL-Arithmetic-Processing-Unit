module conventional_apu #(
    parameter WIDTH = 16
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 enable,
    input  wire [2:0]           opcode,
    input  wire [WIDTH-1:0]     A,
    input  wire [WIDTH-1:0]     B,
    output reg  [2*WIDTH-1:0]   result,
    output reg  [6:0]           flags,
    output reg                  valid
);

    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_MUL = 3'b010;

    localparam OP_AND = 3'b100;
    localparam OP_OR  = 3'b101;
    localparam OP_XOR = 3'b110;
    localparam OP_NOT = 3'b111;

    // 1. Continuous Execution (NO OPERAND ISOLATION)
    wire [WIDTH-1:0]     add_result;
    wire                 add_carry;
    wire [WIDTH-1:0]     sub_result;
    wire                 sub_borrow;
    wire [(2*WIDTH)-1:0] mul_result;
    wire [WIDTH-1:0]     logic_result;

    adder #(.WIDTH(WIDTH)) u_adder (
        .a(A), .b(B), .sum(add_result), .carry(add_carry)
    );

    subtractor #(.WIDTH(WIDTH)) u_subtractor (
        .a(A), .b(B), .diff(sub_result), .borrow(sub_borrow)
    );

    multiplier #(.WIDTH(WIDTH)) u_multiplier (
        .a(A), .b(B), .product(mul_result)
    );

    logic_unit #(.WIDTH(WIDTH)) u_logic_unit (
        .a(A), .b(B), .opcode(opcode), .result(logic_result)
    );

    // 2. Output Multiplexer
    reg [2*WIDTH-1:0] next_result;
    reg [6:0]         next_flags;

    always @(*) begin
        next_result = {2*WIDTH{1'b0}};
        next_flags  = 7'b0;

        case (opcode)
            OP_ADD: begin
                next_result = {{WIDTH{1'b0}}, add_result};
                next_flags[0] = (add_result == {WIDTH{1'b0}});
                next_flags[1] = add_result[WIDTH-1];
                next_flags[2] = add_carry;
                next_flags[3] = 1'b0;
                next_flags[4] = (~(A[WIDTH-1] ^ B[WIDTH-1])) & (add_result[WIDTH-1] ^ A[WIDTH-1]);
                next_flags[5] = ~(^add_result);
                next_flags[6] = 1'b0;
            end
            OP_SUB: begin
                next_result = {{WIDTH{1'b0}}, sub_result};
                next_flags[0] = (sub_result == {WIDTH{1'b0}});
                next_flags[1] = sub_result[WIDTH-1];
                next_flags[2] = 1'b0;
                next_flags[3] = sub_borrow;
                next_flags[4] = (A[WIDTH-1] ^ B[WIDTH-1]) & (sub_result[WIDTH-1] ^ A[WIDTH-1]);
                next_flags[5] = ~(^sub_result);
                next_flags[6] = 1'b0;
            end
            OP_MUL: begin
                next_result = mul_result;
                next_flags[0] = (mul_result == {(2*WIDTH){1'b0}});
                next_flags[1] = mul_result[(2*WIDTH)-1];
                next_flags[2] = 1'b0;
                next_flags[3] = 1'b0;
                next_flags[4] = 1'b0;
                next_flags[5] = ~(^mul_result);
                next_flags[6] = 1'b0;
            end
            OP_AND, OP_OR, OP_XOR, OP_NOT: begin
                next_result = {{WIDTH{1'b0}}, logic_result};
                next_flags[0] = (logic_result == {WIDTH{1'b0}});
                next_flags[1] = logic_result[WIDTH-1];
                next_flags[2] = 1'b0;
                next_flags[3] = 1'b0;
                next_flags[4] = 1'b0;
                next_flags[5] = ~(^logic_result);
                next_flags[6] = 1'b0;
            end
            default: begin
                next_result = {2*WIDTH{1'b0}};
                next_flags  = 7'b0;
            end
        endcase
    end

    // 3. Sequential Logic (NO CLOCK GATING)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result <= {2*WIDTH{1'b0}};
            flags  <= 7'b0;
            valid  <= 1'b0;
        end
        else begin
            valid <= enable;
            
            if (enable) begin
                result <= next_result;
                flags  <= next_flags;
            end
        end
    end

endmodule
