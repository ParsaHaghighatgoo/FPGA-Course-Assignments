`timescale 1ns/1ps

module fir3_low_latency_tb;

  localparam W  = 16;
  localparam CW = 16;
  localparam OW = 32;

  reg clk = 0;
  reg rst = 1;
  reg  signed [W-1:0]  x;
  wire signed [OW-1:0] y;

  // Example coefficients: A=1, B=2, C=3
  fir3_low_latency #(.W(W), .CW(CW), .OW(OW), .A(16'sd1), .B(16'sd2), .C(16'sd3)) dut (
    .clk(clk), .rst(rst), .x(x), .y(y)
  );

  always #5 clk = ~clk; // 100 MHz

  integer n;

  initial begin
    x = 0;

    // reset for a few cycles
    #25;
    rst = 0;

    // apply samples
    for (n = 0; n < 12; n = n + 1) begin
      @(posedge clk);
      x <= n;  // x(n) = 0,1,2,3,...
    end

    @(posedge clk);
    $finish;
  end

endmodule
