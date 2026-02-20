`timescale 1ns/1ps

module tb_lfsr16_galois;

  reg         clk;
  reg         rst_n;
  reg         en;
  wire [15:0] state;

  integer i;

  // DUT
  lfsr16_galois dut (
    .clk   (clk),
    .rst_n (rst_n),
    .en    (en),
    .state (state)
  );

  // Clock: 10ns period (100 MHz)
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    // Init
    rst_n = 1'b1;
    en    = 1'b0;

    // Apply async active-low reset
    #2;
    rst_n = 1'b0;
    #15;
    rst_n = 1'b1;

    // Enable shifting
    en = 1'b1;

    $display("Time(ns)\tCycle\tRST_N\tEN\tSTATE");
    $monitor("%0t\t\t%0d\t%b\t%b\t0x%04h", $time, i, rst_n, en, state);

    // Run for at least 100 cycles
    for (i = 0; i < 120; i = i + 1) begin
      @(posedge clk);

      // Verify it never becomes all-zero
      if (state == 16'h0000) begin
        $display("ERROR: LFSR entered all-zero state at cycle %0d (time=%0t)", i, $time);
        $stop;
      end

      // Demonstrate enable works: pause shifting briefly
      if (i == 50) en = 1'b0;
      if (i == 55) en = 1'b1;
    end

    $display("TB DONE: no all-zero state observed.");
    $finish;
  end

endmodule
