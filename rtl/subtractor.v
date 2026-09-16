module subtractor #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] diff
);

    assign diff = a - b;

endmodule
