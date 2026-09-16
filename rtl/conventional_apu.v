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
    localparam OP_DIV = 3'b011;
    localparam OP_AND = 3'b100;
    localparam OP_OR  = 3'b101;
    localparam OP_XOR = 3'b110;
    localparam OP_NOT = 3'b111;

    /*
     * Dedicated arithmetic datapaths
     */

    wire [WIDTH-1:0] add_result;
    wire             add_carry;

    wire [WIDTH-1:0] sub_result;
    wire             sub_borrow;

    wire [2*WIDTH-1:0] mul_result;

    wire [WIDTH-1:0] div_result;

    assign {add_carry, add_result} =
        {1'b0, A} + {1'b0, B};

    assign sub_result = A - B;

    assign sub_borrow = (A < B);

    assign mul_result = A * B;

    assign div_result =
        (B != {WIDTH{1'b0}})
        ? (A / B)
        : {WIDTH{1'b0}};


    /*
     * Logic datapath
     */

    reg [WIDTH-1:0] logic_result;

    always @(*) begin
        case (opcode)

            OP_AND:
                logic_result = A & B;

            OP_OR:
                logic_result = A | B;

            OP_XOR:
                logic_result = A ^ B;

            OP_NOT:
                logic_result = ~A;

            default:
                logic_result = {WIDTH{1'b0}};

        endcase
    end


    /*
     * Result selection
     */

    reg [2*WIDTH-1:0] selected_result;

    reg [WIDTH-1:0] selected_16bit_result;

    always @(*) begin

        selected_result =
            {2*WIDTH{1'b0}};

        selected_16bit_result =
            {WIDTH{1'b0}};

        case (opcode)

            OP_ADD: begin
                selected_16bit_result = add_result;
                selected_result =
                    {{WIDTH{1'b0}}, add_result};
            end

            OP_SUB: begin
                selected_16bit_result = sub_result;
                selected_result =
                    {{WIDTH{1'b0}}, sub_result};
            end

            OP_MUL: begin
                selected_result = mul_result;
                selected_16bit_result =
                    mul_result[WIDTH-1:0];
            end

            OP_DIV: begin
                selected_16bit_result = div_result;
                selected_result =
                    {{WIDTH{1'b0}}, div_result};
            end

            OP_AND: begin
                selected_16bit_result = logic_result;
                selected_result =
                    {{WIDTH{1'b0}}, logic_result};
            end

            OP_OR: begin
                selected_16bit_result = logic_result;
                selected_result =
                    {{WIDTH{1'b0}}, logic_result};
            end

            OP_XOR: begin
                selected_16bit_result = logic_result;
                selected_result =
                    {{WIDTH{1'b0}}, logic_result};
            end

            OP_NOT: begin
                selected_16bit_result = logic_result;
                selected_result =
                    {{WIDTH{1'b0}}, logic_result};
            end

            default: begin
                selected_result =
                    {2*WIDTH{1'b0}};

                selected_16bit_result =
                    {WIDTH{1'b0}};
            end

        endcase
    end


    /*
     * Flag generation
     *
     * [0] Z = Zero
     * [1] N = Negative
     * [2] C = Carry
     * [3] B = Borrow
     * [4] V = Signed overflow
     * [5] P = Even parity
     * [6] D = Divide-by-zero
     */

    reg [6:0] next_flags;

    always @(*) begin

        next_flags = 7'b0;

        /*
         * Zero flag
         */
        next_flags[0] =
            (selected_result ==
             {2*WIDTH{1'b0}});


        /*
         * Negative flag
         */
        if (opcode == OP_MUL)
            next_flags[1] =
                selected_result[2*WIDTH-1];
        else
            next_flags[1] =
                selected_result[WIDTH-1];


        /*
         * Even parity
         */
        if (opcode == OP_MUL)
            next_flags[5] =
                ~(^selected_result);
        else
            next_flags[5] =
                ~(^selected_16bit_result);


        /*
         * Operation-specific flags
         */
        case (opcode)

            OP_ADD: begin

                next_flags[2] =
                    add_carry;

                next_flags[4] =
                    (~(A[WIDTH-1] ^ B[WIDTH-1])) &
                    (add_result[WIDTH-1] ^ A[WIDTH-1]);

            end

            OP_SUB: begin

                next_flags[3] =
                    sub_borrow;

                next_flags[4] =
                    (A[WIDTH-1] ^ B[WIDTH-1]) &
                    (sub_result[WIDTH-1] ^ A[WIDTH-1]);

            end

            OP_DIV: begin

                next_flags[6] =
                    (B == {WIDTH{1'b0}});

            end

            default: begin
            end

        endcase

    end


    /*
     * Registered outputs
     */

    always @(posedge clk) begin

        if (rst) begin

            result <= {2*WIDTH{1'b0}};
            flags  <= 7'b0;
            valid  <= 1'b0;

        end

        else if (enable) begin

            result <= selected_result;
            flags  <= next_flags;
            valid  <= 1'b1;

        end

        else begin

            valid <= 1'b0;

        end

    end

endmodule
