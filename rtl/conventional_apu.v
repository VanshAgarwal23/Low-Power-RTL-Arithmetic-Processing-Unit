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

    wire [WIDTH-1:0]       add_result;
    wire [WIDTH-1:0]       sub_result;
    wire [2*WIDTH-1:0]     mul_result;
    wire [WIDTH-1:0]       div_result;
    wire [WIDTH-1:0]       logic_result;

    wire                   add_carry;
    wire                   sub_borrow;

    /*
     * Arithmetic units
     */

    adder #(.WIDTH(WIDTH)) u_adder (
        .a     (A),
        .b     (B),
        .sum   (add_result),
        .carry (add_carry)
    );

    subtractor #(.WIDTH(WIDTH)) u_subtractor (
        .a      (A),
        .b      (B),
        .diff   (sub_result),
        .borrow (sub_borrow)
    );

    multiplier #(.WIDTH(WIDTH)) u_multiplier (
        .a       (A),
        .b       (B),
        .product (mul_result)
    );

    divider #(.WIDTH(WIDTH)) u_divider (
        .dividend (A),
        .divisor  (B),
        .quotient (div_result)
    );

    logic_unit #(.WIDTH(WIDTH)) u_logic_unit (
        .a      (A),
        .b      (B),
        .opcode (opcode),
        .result (logic_result)
    );

    /*
     * Intermediate result and flags
     */

    reg [2*WIDTH-1:0] next_result;
    reg [6:0]         next_flags;

    reg [WIDTH-1:0]   selected_16bit_result;

    reg signed [WIDTH-1:0] signed_A;
    reg signed [WIDTH-1:0] signed_B;
    reg signed [WIDTH-1:0] signed_result;

    always @(*) begin

        next_result = {(2*WIDTH){1'b0}};
        next_flags  = 7'b0;

        selected_16bit_result = {WIDTH{1'b0}};

        signed_A      = A;
        signed_B      = B;
        signed_result = {WIDTH{1'b0}};

        case (opcode)

            /*
             * ADD
             */
            3'b000: begin

                selected_16bit_result = add_result;

                next_result = {{WIDTH{1'b0}}, add_result};

                next_flags[2] = add_carry;

                /*
                 * Signed overflow:
                 * Same-sign operands produce opposite-sign result.
                 */
                next_flags[4] =
                    (~(A[WIDTH-1] ^ B[WIDTH-1])) &
                    (add_result[WIDTH-1] ^ A[WIDTH-1]);

            end

            /*
             * SUB
             */
            3'b001: begin

                selected_16bit_result = sub_result;

                next_result = {{WIDTH{1'b0}}, sub_result};

                next_flags[3] = sub_borrow;

                /*
                 * Signed subtraction overflow.
                 */
                next_flags[4] =
                    (A[WIDTH-1] ^ B[WIDTH-1]) &
                    (sub_result[WIDTH-1] ^ A[WIDTH-1]);

            end

            /*
             * MUL
             */
            3'b010: begin

                next_result = mul_result;

            end

            /*
             * DIV
             */
            3'b011: begin

                selected_16bit_result = div_result;

                next_result = {{WIDTH{1'b0}}, div_result};

                if (B == 0)
                    next_flags[6] = 1'b1;

            end

            /*
             * LOGIC OPERATIONS
             */
            3'b100,
            3'b101,
            3'b110,
            3'b111: begin

                selected_16bit_result = logic_result;

                next_result = {{WIDTH{1'b0}}, logic_result};

            end

            default: begin

                next_result = {(2*WIDTH){1'b0}};
                next_flags  = 7'b0;

            end

        endcase

        /*
         * Zero flag
         */
        if (next_result == {(2*WIDTH){1'b0}})
            next_flags[0] = 1'b1;

        /*
         * Negative flag
         */
        if (opcode == 3'b010)
            next_flags[1] = next_result[(2*WIDTH)-1];
        else
            next_flags[1] = selected_16bit_result[WIDTH-1];

        /*
         * Even parity flag
         */
        if (opcode == 3'b010)
            next_flags[5] = ~(^next_result);
        else
            next_flags[5] = ~(^selected_16bit_result);

    end

    /*
     * Registered output and status flags
     */

    always @(posedge clk) begin

        if (rst) begin

            result <= {(2*WIDTH){1'b0}};
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
