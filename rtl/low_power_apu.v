module low_power_apu #(
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

    // --------------------------------------------------
    // Opcode definitions
    // --------------------------------------------------

    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_MUL = 3'b010;
    localparam OP_DIV = 3'b011;

    localparam OP_AND = 3'b100;
    localparam OP_OR  = 3'b101;
    localparam OP_XOR = 3'b110;
    localparam OP_NOT = 3'b111;


    // --------------------------------------------------
    // Operation enables
    // --------------------------------------------------

    wire add_en;
    wire sub_en;
    wire mul_en;
    wire div_en;
    wire logic_en;

    assign add_en   = enable && (opcode == OP_ADD);
    assign sub_en   = enable && (opcode == OP_SUB);
    assign mul_en   = enable && (opcode == OP_MUL);
    assign div_en   = enable && (opcode == OP_DIV);
    assign logic_en = enable &&
                      ((opcode == OP_AND) ||
                       (opcode == OP_OR)  ||
                       (opcode == OP_XOR) ||
                       (opcode == OP_NOT));


    // --------------------------------------------------
    // Isolated operands
    // --------------------------------------------------

    wire [WIDTH-1:0] add_a;
    wire [WIDTH-1:0] add_b;

    wire [WIDTH-1:0] sub_a;
    wire [WIDTH-1:0] sub_b;

    wire [WIDTH-1:0] mul_a;
    wire [WIDTH-1:0] mul_b;

    wire [WIDTH-1:0] div_a;
    wire [WIDTH-1:0] div_b;

    wire [WIDTH-1:0] logic_a;
    wire [WIDTH-1:0] logic_b;


    operand_isolation #(
        .WIDTH(WIDTH)
    ) isolation (
        .a(A),
        .b(B),

        .add_en(add_en),
        .sub_en(sub_en),
        .mul_en(mul_en),
        .div_en(div_en),
        .logic_en(logic_en),

        .add_a(add_a),
        .add_b(add_b),

        .sub_a(sub_a),
        .sub_b(sub_b),

        .mul_a(mul_a),
        .mul_b(mul_b),

        .div_a(div_a),
        .div_b(div_b),

        .logic_a(logic_a),
        .logic_b(logic_b)
    );


    // --------------------------------------------------
    // Arithmetic units
    // --------------------------------------------------

    wire [WIDTH-1:0] add_result;
    wire             add_carry;

    wire [WIDTH-1:0] sub_result;
    wire             sub_borrow;

    wire [2*WIDTH-1:0] mul_result;

    wire [WIDTH-1:0] div_result;


    adder #(
        .WIDTH(WIDTH)
    ) u_adder (
        .a(add_a),
        .b(add_b),
        .sum(add_result),
        .carry(add_carry)
    );


    subtractor #(
        .WIDTH(WIDTH)
    ) u_subtractor (
        .a(sub_a),
        .b(sub_b),
        .diff(sub_result),
        .borrow(sub_borrow)
    );


    multiplier #(
        .WIDTH(WIDTH)
    ) u_multiplier (
        .a(mul_a),
        .b(mul_b),
        .product(mul_result)
    );


    divider #(
        .WIDTH(WIDTH)
    ) u_divider (
        .dividend(div_a),
        .divisor(div_b),
        .quotient(div_result)
    );


    // --------------------------------------------------
    // Logic unit
    // --------------------------------------------------

    wire [WIDTH-1:0] logic_result;

    logic_unit #(
        .WIDTH(WIDTH)
    ) u_logic (
        .a(logic_a),
        .b(logic_b),
        .opcode(opcode),
        .result(logic_result)
    );


    // --------------------------------------------------
    // Combinational next-state signals
    // --------------------------------------------------

    reg [2*WIDTH-1:0] next_result;
    reg [6:0]         next_flags;

    reg [WIDTH-1:0]   selected_result;


    // --------------------------------------------------
    // Next-state generation
    // --------------------------------------------------

    always @(*) begin

        next_result     = {2*WIDTH{1'b0}};
        next_flags      = 7'b0;
        selected_result = {WIDTH{1'b0}};

        case (opcode)

            OP_ADD: begin

                selected_result = add_result;

                next_result = {{WIDTH{1'b0}}, add_result};

                next_flags[2] = add_carry;

                next_flags[4] =
                    (~(A[WIDTH-1] ^ B[WIDTH-1])) &
                    (add_result[WIDTH-1] ^ A[WIDTH-1]);

            end


            OP_SUB: begin

                selected_result = sub_result;

                next_result = {{WIDTH{1'b0}}, sub_result};

                next_flags[3] = sub_borrow;

                next_flags[4] =
                    (A[WIDTH-1] ^ B[WIDTH-1]) &
                    (sub_result[WIDTH-1] ^ A[WIDTH-1]);

            end


            OP_MUL: begin

                next_result = mul_result;

            end


            OP_DIV: begin

                selected_result = div_result;

                next_result = {{WIDTH{1'b0}}, div_result};

                if (B == {WIDTH{1'b0}})
                    next_flags[6] = 1'b1;

            end


            OP_AND: begin

                selected_result = logic_result;

                next_result = {{WIDTH{1'b0}}, logic_result};

            end


            OP_OR: begin

                selected_result = logic_result;

                next_result = {{WIDTH{1'b0}}, logic_result};

            end


            OP_XOR: begin

                selected_result = logic_result;

                next_result = {{WIDTH{1'b0}}, logic_result};

            end


            OP_NOT: begin

                selected_result = logic_result;

                next_result = {{WIDTH{1'b0}}, logic_result};

            end


            default: begin

                next_result = {2*WIDTH{1'b0}};

            end

        endcase


        // --------------------------------------------------
        // Zero flag
        // --------------------------------------------------

        if (next_result == {2*WIDTH{1'b0}})
            next_flags[0] = 1'b1;


        // --------------------------------------------------
        // Negative flag
        // --------------------------------------------------

        if (opcode == OP_MUL)
            next_flags[1] = next_result[2*WIDTH-1];
        else
            next_flags[1] = selected_result[WIDTH-1];


        // --------------------------------------------------
        // Even parity
        // --------------------------------------------------

        if (opcode == OP_MUL)
            next_flags[5] = ~(^next_result);
        else
            next_flags[5] = ~(^selected_result);

    end


    // --------------------------------------------------
    // Registered output
    // --------------------------------------------------

    always @(posedge clk) begin

        if (rst) begin

            result <= {2*WIDTH{1'b0}};
            flags  <= 7'b0;
            valid  <= 1'b0;

        end

        else if (enable) begin

            result <= next_result;
            flags  <= next_flags;
            valid  <= 1'b1;

        end

        else begin

            valid <= 1'b0;

        end

    end

endmodule
