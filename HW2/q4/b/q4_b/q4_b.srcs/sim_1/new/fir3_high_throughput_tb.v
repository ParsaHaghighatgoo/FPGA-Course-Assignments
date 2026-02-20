`timescale 1ns/1ps

module fir3_high_throughput_tb;

  // Match DUT parameters
  localparam W  = 16;
  localparam CW = 16;
  localparam OW = 32;

  reg clk = 0;
  reg rst = 1;
  reg  signed [W-1:0]  x;
  wire signed [OW-1:0] y;

  // Example coefficients (same as before)
  // y(n) = 1*x(n) + 2*x(n-1) + 3*x(n-2)
  fir3_high_throughput #(
    .W(W), .CW(CW), .OW(OW),
    .A(16'sd1), .B(16'sd2), .C(16'sd3)
  ) dut (
    .clk(clk),
    .rst(rst),
    .x(x),
    .y(y)
  );

  // 100 MHz clock (10 ns period)
  always #5 clk = ~clk;

  integer n;

  initial begin
    // init
    x = 0;

    // hold reset a bit
    #25;
    rst = 0;

    // apply 12 samples: x(n)=0..11
    for (n = 0; n < 12; n = n + 1) begin
      @(posedge clk);
      x <= n;
    end

    // wait a few extra cycles so pipeline output finishes
    repeat (6) @(posedge clk);

    $finish;
  end

endmodule
