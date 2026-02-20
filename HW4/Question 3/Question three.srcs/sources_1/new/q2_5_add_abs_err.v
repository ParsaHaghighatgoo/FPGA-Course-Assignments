`timescale 1ns/1ps

// Q2.5 adder + absolute error in Q2.5
// Inputs:  signed Q16.16 (32-bit)
// Outputs: signed Q2.5  (16-bit scaled integers)
//
// Steps:
// 1) Quantize a and b to Q2.5 (round-to-nearest, ties away from zero)
// 2) Add them in Q2.5 -> sum_q2_5
// 3) Compute true sum in Q16.16, then quantize to Q2.5 -> true_sum_q2_5
// 4) abs_err_q2_5 = |true_sum_q2_5 - sum_q2_5|
module q2_5_add_abs_err
#(
    parameter IN_FRAC  = 16, // Q16.16 fractional bits
    parameter OUT_FRAC = 5   // Q2.5 fractional bits
)
(
    input  signed [31:0] a_q16_16,
    input  signed [31:0] b_q16_16,

    output reg signed [15:0] a_q2_5,
    output reg signed [15:0] b_q2_5,
    output reg signed [15:0] sum_q2_5,

    output reg signed [15:0] true_sum_q2_5,
    output reg signed [15:0] abs_err_q2_5
);

    // For Q16.16 -> Q2.5, SHIFT = 16-5 = 11
    localparam SHIFT = (IN_FRAC - OUT_FRAC);

    // Round-to-nearest when shifting right by SHIFT bits.
    // "ties away from zero" implemented by +/- half LSB before arithmetic shift.
    function signed [15:0] round_q16_16_to_q2_5;
        input signed [31:0] x;
        reg   signed [31:0] adj;
        reg   signed [31:0] shifted;
        begin
            if (SHIFT <= 0) begin
                shifted = x <<< (-SHIFT);
            end else begin
                if (x >= 0)
                    adj = x + (32'sd1 <<< (SHIFT-1));
                else
                    adj = x - (32'sd1 <<< (SHIFT-1));

                shifted = adj >>> SHIFT; // arithmetic shift right
            end

            round_q16_16_to_q2_5 = shifted[15:0];
        end
    endfunction

    function signed [15:0] abs16;
        input signed [15:0] x;
        begin
            if (x < 0)
                abs16 = -x;
            else
                abs16 = x;
        end
    endfunction

    reg signed [31:0] true_sum_q16_16;
    reg signed [15:0] diff_q2_5;

    always @* begin
        // Quantize each input to Q2.5
        a_q2_5 = round_q16_16_to_q2_5(a_q16_16);
        b_q2_5 = round_q16_16_to_q2_5(b_q16_16);

        // Q2.5 addition
        sum_q2_5 = a_q2_5 + b_q2_5;

        // True sum computed in higher precision then quantized to Q2.5
        true_sum_q16_16 = a_q16_16 + b_q16_16;
        true_sum_q2_5   = round_q16_16_to_q2_5(true_sum_q16_16);

        // Absolute error in Q2.5
        diff_q2_5    = true_sum_q2_5 - sum_q2_5;
        abs_err_q2_5 = abs16(diff_q2_5);
    end

endmodule
