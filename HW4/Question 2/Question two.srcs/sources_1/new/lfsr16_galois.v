`timescale 1ns/1ps

module lfsr16_galois (
    input  wire        clk,
    input  wire        rst_n,   // active-low asynchronous reset
    input  wire        en,      // clock enable
    output reg  [15:0] state    // current LFSR state (pseudo-random)
);

    // Taps: 16,14,13,11 => polynomial x^16 + x^14 + x^13 + x^11 + 1
    // Common Galois right-shift mask for that polynomial:
    localparam [15:0] GALOIS_MASK = 16'hB400;

    // Choose any NON-ZERO seed (must not be 16'h0000)
    localparam [15:0] SEED = 16'hACE1;

    wire feedback = state[0]; // LSB is the shifted-out bit in right-shift form

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= SEED;
        end else if (en) begin
            // Galois form (right shift):
            // shift right, old LSB becomes new MSB
            state <= {feedback, state[15:1]} ^ (feedback ? GALOIS_MASK : 16'h0000);
        end
        // else: hold state when en=0
    end

endmodule
