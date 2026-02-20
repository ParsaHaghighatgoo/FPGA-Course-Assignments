`timescale 1ns/1ps

module fir3_low_latency #(
    parameter integer W  = 16,   // input width
    parameter integer CW = 16,   // coefficient width
    parameter integer OW = 32,   // output width (accum width)
    parameter signed [CW-1:0] A = 16'sd1,
    parameter signed [CW-1:0] B = 16'sd2,
    parameter signed [CW-1:0] C = 16'sd3
)(
    input  wire                    clk,
    input  wire                    rst,   // synchronous reset
    input  wire signed [W-1:0]      x,
    output reg  signed [OW-1:0]     y
);

    // Delay line registers
    reg signed [W-1:0] x1, x2;  // x(n-1), x(n-2)

    // Combinational products and sum (lowest latency, no pipeline)
    wire signed [W+CW-1:0] p0 = x  * A;
    wire signed [W+CW-1:0] p1 = x1 * B;
    wire signed [W+CW-1:0] p2 = x2 * C;

    wire signed [OW-1:0] sum = {{(OW-(W+CW)){p0[W+CW-1]}}, p0} +
                               {{(OW-(W+CW)){p1[W+CW-1]}}, p1} +
                               {{(OW-(W+CW)){p2[W+CW-1]}}, p2};

    always @(posedge clk) begin
        if (rst) begin
            x1 <= {W{1'b0}};
            x2 <= {W{1'b0}};
            y  <= {OW{1'b0}};
        end else begin
            // shift register for delays
            x2 <= x1;
            x1 <= x;

            // registered output
            y  <= sum;
        end
    end

endmodule
