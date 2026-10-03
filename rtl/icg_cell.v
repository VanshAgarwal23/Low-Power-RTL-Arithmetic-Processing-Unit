module ICG_CELL (
    input  wire clk,
    input  wire en,
    input  wire te,     // Test Enable (for DFT scan chains)
    output wire gclk
);
    reg latch_en;
    
    // Negative-level sensitive latch prevents clock glitches
    always @(clk or en or te) begin
        if (!clk) begin
            latch_en <= en | te;
        end
    end
    
    assign gclk = clk & latch_en;
endmodule
