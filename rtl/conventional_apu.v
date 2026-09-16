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
    output reg                  valid
);

    wire [WIDTH-1:0] add_result;
    wire [WIDTH-1:0] sub_result;
    wire [2*WIDTH-1:0] mul_result;
    wire [WIDTH-1:0] div_result;
    wire [WIDTH-1:0] logic_result;

    /*
     * Arithmetic units
     */
    adder #(.WIDTH(WIDTH)) u_adder (
        .a   (A),
        .b   (B),
        .sum (add_result)
    );

    subtractor #(.WIDTH(WIDTH)) u_subtractor (
        .a    (A),
        .b    (B),
        .diff (sub_result)
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

    /*
     * Logic unit
     */
    logic_unit #(.WIDTH(WIDTH)) u_logic_unit (
        .a      (A),
        .b      (B),
        .opcode (opcode),
        .result (logic_result)
    );

    /*
     * Registered output
     */
    always @(posedge clk) begin

        if (rst) begin
            result <= {(2*WIDTH){1'b0}};
            valid  <= 1'b0;
        end

        else if (enable) begin

            case (opcode)

                3'b000: result <= {{WIDTH{1'b0}}, add_result};

                3'b001: result <= {{WIDTH{1'b0}}, sub_result};

                3'b010: result <= mul_result;

                3'b011: result <= {{WIDTH{1'b0}}, div_result};

                3'b100,
                3'b101,
                3'b110,
                3'b111: result <= {{WIDTH{1'b0}}, logic_result};

                default: result <= {(2*WIDTH){1'b0}};

            endcase

            valid <= 1'b1;

        end

        else begin
            valid <= 1'b0;
        end

    end

endmodule
