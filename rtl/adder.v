module adder #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] sum
);

    assign sum = a + b;

endmodule
