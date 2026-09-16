module divider #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] dividend,
    input  wire [WIDTH-1:0] divisor,
    output wire [WIDTH-1:0] quotient
);

    assign quotient = (divisor != 0) ? (dividend / divisor) : {WIDTH{1'b0}};

endmodule
