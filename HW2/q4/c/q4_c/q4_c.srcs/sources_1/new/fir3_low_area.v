`timescale 1ns/1ps

module fir3_low_area #(
    parameter integer W  = 16,
    parameter integer CW = 16,
    parameter integer OW = 32,
    parameter signed [CW-1:0] A = 16'sd1,
    parameter signed [CW-1:0] B = 16'sd2,
    parameter signed [CW-1:0] C = 16'sd3
)(
    input  wire                    clk,
    input  wire                    rst,      // synchronous reset
    input  wire                    x_valid,  // new input sample valid
    input  wire signed [W-1:0]      x,
    output reg                     y_valid,  // output valid pulse
    output reg  signed [OW-1:0]     y
);

    // Delay line for samples
    reg signed [W-1:0] x1, x2;  // x(n-1), x(n-2)

    // State machine / phase counter (0,1,2)
    reg [1:0] phase;
    reg busy;

    // Accumulator register
    reg signed [OW-1:0] acc;

    // Selected sample and coefficient
    reg signed [W-1:0]  x_sel;
    reg signed [CW-1:0] c_sel;

    // Shared multiplier output
    wire signed [W+CW-1:0] prod_w = x_sel * c_sel;

    // Sign-extend product to accumulator width
    wire signed [OW-1:0] prod_ext = {{(OW-(W+CW)){prod_w[W+CW-1]}}, prod_w};

    always @(*) begin
        // defaults
        x_sel = x;
        c_sel = A;

        case (phase)
            2'd0: begin x_sel = x;  c_sel = A; end       // a*x(n)
            2'd1: begin x_sel = x1; c_sel = B; end       // b*x(n-1)
            2'd2: begin x_sel = x2; c_sel = C; end       // c*x(n-2)
            default: begin x_sel = x; c_sel = A; end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            x1      <= 0;
            x2      <= 0;
            phase   <= 0;
            busy    <= 0;
            acc     <= 0;
            y       <= 0;
            y_valid <= 0;
        end else begin
            y_valid <= 0; // default: pulse only when finished

            // Start a new computation only when not busy and x_valid is asserted
            if (!busy) begin
                if (x_valid) begin
                    // shift in new sample
                    x2    <= x1;
                    x1    <= x;

                    // start MAC sequence
                    busy  <= 1'b1;
                    phase <= 2'd0;
                    acc   <= 0;       // clear accumulator
                end
            end else begin
                // busy: accumulate current phase product
                acc <= acc + prod_ext;

                if (phase == 2'd2) begin
                    // finished all 3 taps
                    y       <= acc + prod_ext; // include last add
                    y_valid <= 1'b1;
                    busy    <= 1'b0;
                    phase   <= 2'd0;
                end else begin
                    phase <= phase + 2'd1;
                end
            end
        end
    end

endmodule
