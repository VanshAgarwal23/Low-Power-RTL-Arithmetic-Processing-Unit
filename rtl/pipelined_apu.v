module pipelined_apu #(
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

    /*
     * Opcode definitions
     */
    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_MUL = 3'b010;
    localparam OP_DIV = 3'b011;
    localparam OP_AND = 3'b100;
    localparam OP_OR  = 3'b101;
    localparam OP_XOR = 3'b110;
    localparam OP_NOT = 3'b111;


    /*
     * ============================================================
     * STAGE 1
     * Operation execution
     * ============================================================
     */

    wire [WIDTH-1:0] add_result;
    wire             add_carry;

    wire [WIDTH-1:0] sub_result;
    wire             sub_borrow;

    wire [2*WIDTH-1:0] mul_result;

    wire [WIDTH-1:0] div_result;

    reg [WIDTH-1:0] logic_result;


    /*
     * Arithmetic datapaths
     */

    assign {add_carry, add_result} =
        {1'b0, A} + {1'b0, B};

    assign sub_result =
        A - B;

    assign sub_borrow =
        (A < B);

    assign mul_result =
        A * B;

    assign div_result =
        (B != {WIDTH{1'b0}})
        ? (A / B)
        : {WIDTH{1'b0}};


    /*
     * Logic datapath
     */

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
     * Stage-1 result selection
     */

    reg [2*WIDTH-1:0] stage1_result;

    always @(*) begin

        stage1_result =
            {2*WIDTH{1'b0}};

        case (opcode)

            OP_ADD:
                stage1_result =
                    {{WIDTH{1'b0}}, add_result};

            OP_SUB:
                stage1_result =
                    {{WIDTH{1'b0}}, sub_result};

            OP_MUL:
                stage1_result =
                    mul_result;

            OP_DIV:
                stage1_result =
                    {{WIDTH{1'b0}}, div_result};

            OP_AND:
                stage1_result =
                    {{WIDTH{1'b0}}, logic_result};

            OP_OR:
                stage1_result =
                    {{WIDTH{1'b0}}, logic_result};

            OP_XOR:
                stage1_result =
                    {{WIDTH{1'b0}}, logic_result};

            OP_NOT:
                stage1_result =
                    {{WIDTH{1'b0}}, logic_result};

            default:
                stage1_result =
                    {2*WIDTH{1'b0}};

        endcase
    end


    /*
     * Information registered between Stage 1 and Stage 2
     */

    reg [2*WIDTH-1:0] stage1_result_reg;
    reg [2:0]         stage1_opcode_reg;

    reg [WIDTH-1:0]   stage1_A_reg;
    reg [WIDTH-1:0]   stage1_B_reg;

    reg               stage1_add_carry_reg;
    reg               stage1_sub_borrow_reg;

    reg               stage1_valid_reg;


    /*
     * Stage-1 pipeline register
     */

    always @(posedge clk) begin

        if (rst) begin

            stage1_result_reg      <= {2*WIDTH{1'b0}};
            stage1_opcode_reg      <= OP_ADD;

            stage1_A_reg           <= {WIDTH{1'b0}};
            stage1_B_reg           <= {WIDTH{1'b0}};

            stage1_add_carry_reg   <= 1'b0;
            stage1_sub_borrow_reg  <= 1'b0;

            stage1_valid_reg       <= 1'b0;

        end

        else begin

            stage1_valid_reg <= enable;

            if (enable) begin

                stage1_result_reg     <= stage1_result;
                stage1_opcode_reg     <= opcode;

                stage1_A_reg          <= A;
                stage1_B_reg          <= B;

                stage1_add_carry_reg  <= add_carry;
                stage1_sub_borrow_reg <= sub_borrow;

            end

        end

    end


    /*
     * ============================================================
     * STAGE 2
     * Result and flag generation
     * ============================================================
     */

    reg [6:0] stage2_flags;


    always @(*) begin

        stage2_flags = 7'b0;


        /*
         * Zero flag
         */
        stage2_flags[0] =
            (stage1_result_reg ==
             {2*WIDTH{1'b0}});


        /*
         * Negative flag
         */
        if (stage1_opcode_reg == OP_MUL)

            stage2_flags[1] =
                stage1_result_reg[2*WIDTH-1];

        else

            stage2_flags[1] =
                stage1_result_reg[WIDTH-1];


        /*
         * Even parity
         */
        if (stage1_opcode_reg == OP_MUL)

            stage2_flags[5] =
                ~(^stage1_result_reg);

        else

            stage2_flags[5] =
                ~(^(stage1_result_reg[WIDTH-1:0]));


        /*
         * Operation-specific flags
         */

        case (stage1_opcode_reg)

            OP_ADD: begin

                stage2_flags[2] =
                    stage1_add_carry_reg;

                stage2_flags[4] =
                    (~(stage1_A_reg[WIDTH-1] ^
                       stage1_B_reg[WIDTH-1])) &
                    (stage1_result_reg[WIDTH-1] ^
                     stage1_A_reg[WIDTH-1]);

            end


            OP_SUB: begin

                stage2_flags[3] =
                    stage1_sub_borrow_reg;

                stage2_flags[4] =
                    (stage1_A_reg[WIDTH-1] ^
                     stage1_B_reg[WIDTH-1]) &
                    (stage1_result_reg[WIDTH-1] ^
                     stage1_A_reg[WIDTH-1]);

            end


            OP_DIV: begin

                stage2_flags[6] =
                    (stage1_B_reg ==
                     {WIDTH{1'b0}});

            end


            default: begin
            end

        endcase

    end


    /*
     * Stage-2 output register
     */

    always @(posedge clk) begin

        if (rst) begin

            result <= {2*WIDTH{1'b0}};
            flags  <= 7'b0;
            valid  <= 1'b0;

        end

        else begin

            valid <= stage1_valid_reg;

            if (stage1_valid_reg) begin

                result <= stage1_result_reg;
                flags  <= stage2_flags;

            end

        end

    end

endmodule
