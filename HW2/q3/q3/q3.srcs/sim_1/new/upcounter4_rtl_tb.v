`timescale 1ns/1ps

module upcounter4_rtl_tb;

  reg clk;
  reg rst;
  wire [3:0] out;

  // Instantiate the RTL counter
  upcounter4_rtl dut (
    .clk(clk),
    .rst(rst),
    .out(out)
  );

  // Clock generation: 10 ns period
  always #5 clk = ~clk;

  initial begin
    // Initialize
    clk = 0;
    rst = 1;

    // Apply reset
    #15;
    rst = 0;

    // Let counter run freely
    #200;

    $stop;
  end

endmodule
