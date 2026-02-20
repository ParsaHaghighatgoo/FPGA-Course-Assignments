`timescale 1ns/1ps

module fir3_high_throughput #(
    parameter integer W  = 16,   // input width
    parameter integer CW = 16,   // coefficient width
    parameter integer OW = 32,   // accumulator/output width
    parameter signed [CW-1:0] A = 16'sd1,
    parameter signed [CW-1:0] B = 16'sd2,
    parameter signed [CW-1:0] C = 16'sd3
)(
    input  wire                    clk,
    input  wire                    rst,   // synchronous reset
    input  wire signed [W-1:0]      x,
    output reg  signed [OW-1:0]     y
);

    // Tap delay line registers: x1=x(n-1), x2=x(n-2)
    reg signed [W-1:0] x1, x2;

    // Multiplier outputs (combinational)
    wire signed [W+CW-1:0] p0_w = x  * A;
    wire signed [W+CW-1:0] p1_w = x1 * B;
    wire signed [W+CW-1:0] p2_w = x2 * C;

    // Pipeline Stage 1 regs (after multipliers)
    reg signed [OW-1:0] p0_r, p1_r, p2_r;

    // Pipeline Stage 2 regs (after first adder) + alignment reg for p2
    reg signed [OW-1:0] s1_r;
    reg signed [OW-1:0] p2_d1;

    // Pipeline Stage 3 reg (after final adder)
    reg signed [OW-1:0] s2_r;

    // Sign-extend multiplier outputs up to OW bits
    wire signed [OW-1:0] p0_ext = {{(OW-(W+CW)){p0_w[W+CW-1]}}, p0_w};
    wire signed [OW-1:0] p1_ext = {{(OW-(W+CW)){p1_w[W+CW-1]}}, p1_w};
    wire signed [OW-1:0] p2_ext = {{(OW-(W+CW)){p2_w[W+CW-1]}}, p2_w};

    always @(posedge clk) begin
        if (rst) begin
            // Verilog-safe reset values (NO '0)
            x1    <= 0;
            x2    <= 0;

            p0_r  <= 0;
            p1_r  <= 0;
            p2_r  <= 0;

            s1_r  <= 0;
            p2_d1 <= 0;

            s2_r  <= 0;
            y     <= 0;
        end else begin
            // Update delay line
            x2 <= x1;
            x1 <= x;

            // Stage 1: register products
            p0_r <= p0_ext;
            p1_r <= p1_ext;
            p2_r <= p2_ext;

            // Stage 2: one adder + align p2
            s1_r  <= p0_r + p1_r;
            p2_d1 <= p2_r;

            // Stage 3: final adder + output reg
            s2_r <= s1_r + p2_d1;
            y    <= s2_r;
        end
    end

endmodule
