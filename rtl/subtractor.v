module subtractor #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] diff,
    output wire             borrow
);

    assign diff   = a - b;
    assign borrow = (a < b);

endmodule
