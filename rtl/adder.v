module adder #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] sum,
    output wire             carry
);

    wire [WIDTH:0] full_sum;

    assign full_sum = {1'b0, a} + {1'b0, b};

    assign sum   = full_sum[WIDTH-1:0];
    assign carry = full_sum[WIDTH];

endmodule
