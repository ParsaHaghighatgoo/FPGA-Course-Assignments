`timescale 1ns/1ps

module fir3_low_area_tb;

  localparam W  = 16;
  localparam CW = 16;
  localparam OW = 32;

  reg clk = 0;
  reg rst = 1;
  reg x_valid = 0;
  reg  signed [W-1:0] x;
  wire y_valid;
  wire signed [OW-1:0] y;

  fir3_low_area #(
    .W(W), .CW(CW), .OW(OW),
    .A(16'sd1), .B(16'sd2), .C(16'sd3)
  ) dut (
    .clk(clk), .rst(rst),
    .x_valid(x_valid), .x(x),
    .y_valid(y_valid), .y(y)
  );

  always #5 clk = ~clk; // 100 MHz

  integer n;

  initial begin
    x = 0;

    // reset
    #25 rst = 0;

    // Apply 6 samples, but only assert x_valid when idle (every 3 cycles)
    for (n = 0; n < 6; n = n + 1) begin
      @(posedge clk);
      x <= n;
      x_valid <= 1'b1;

      @(posedge clk);
      x_valid <= 1'b0;

      // wait 2 more cycles (MAC running)
      repeat(2) @(posedge clk);
    end

    repeat(6) @(posedge clk);
    $finish;
  end

endmodule
