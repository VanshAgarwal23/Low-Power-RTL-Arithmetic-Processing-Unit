module operand_isolation #(
    parameter WIDTH = 16
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,

    input wire add_en,
    input wire sub_en,
    input wire mul_en,
    input wire logic_en,

    output wire [WIDTH-1:0] add_a,
    output wire [WIDTH-1:0] add_b,

    output wire [WIDTH-1:0] sub_a,
    output wire [WIDTH-1:0] sub_b,

    output wire [WIDTH-1:0] mul_a,
    output wire [WIDTH-1:0] mul_b,

    output wire [WIDTH-1:0] logic_a,
    output wire [WIDTH-1:0] logic_b
);

    assign add_a = add_en ? a : {WIDTH{1'b0}};
    assign add_b = add_en ? b : {WIDTH{1'b0}};

    assign sub_a = sub_en ? a : {WIDTH{1'b0}};
    assign sub_b = sub_en ? b : {WIDTH{1'b0}};

    assign mul_a = mul_en ? a : {WIDTH{1'b0}};
    assign mul_b = mul_en ? b : {WIDTH{1'b0}};

    assign logic_a = logic_en ? a : {WIDTH{1'b0}};
    assign logic_b = logic_en ? b : {WIDTH{1'b0}};

endmodule
