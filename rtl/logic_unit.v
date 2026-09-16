module logic_unit #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire [2:0] opcode,
    output reg  [WIDTH-1:0] result
);

    always @(*) begin
        case (opcode)
            3'b100: result = a & b;
            3'b101: result = a | b;
            3'b110: result = a ^ b;
            3'b111: result = ~a;
            default: result = {WIDTH{1'b0}};
        endcase
    end

endmodule
