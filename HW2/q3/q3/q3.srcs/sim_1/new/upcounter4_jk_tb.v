`timescale 1ns/1ps

module upcounter4_jk_tb;

  reg clk;
  reg rst;
  wire [3:0] out;

  // Instantiate the JK counter
  upcounter4_jk dut (
    .clk(clk),
    .rst(rst),
    .out(out)
  );

  // Clock generation: 10 ns period
  always #5 clk = ~clk;

  initial begin
    // Initialize signals
    clk = 0;
    rst = 1;

    // Apply reset
    #15;
    rst = 0;

    // Let the counter run
    #200;

    $stop;
  end

endmodule
