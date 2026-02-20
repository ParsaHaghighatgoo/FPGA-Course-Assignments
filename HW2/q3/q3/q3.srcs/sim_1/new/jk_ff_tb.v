`timescale 1ns/1ps

module jk_ff_tb;

  reg clk, rst;
  reg j, k;
  wire q, qbar;

  jk_ff dut (
    .clk(clk), .rst(rst),
    .j(j), .k(k),
    .q(q), .qbar(qbar)
  );

  // 10 ns clock
  always #5 clk = ~clk;

  task step_and_check(input reg exp_q, input [1:0] jk);
    begin
      {j,k} = jk;
      @(posedge clk);
      #1;
      if (q !== exp_q) begin
        $display("? FAIL time=%0t JK=%b exp_q=%b got_q=%b", $time, jk, exp_q, q);
        $stop;
      end else begin
        $display("? PASS time=%0t JK=%b q=%b qbar=%b", $time, jk, q, qbar);
      end
    end
  endtask

  initial begin
    clk = 0; rst = 1; j = 0; k = 0;

    // reset -> q should become 0
    #2;
    rst = 1;
    #8;
    rst = 0;

    // Start from known q=0
    // 00 hold (q stays 0)
    step_and_check(1'b0, 2'b00);

    // 10 set (q becomes 1)
    step_and_check(1'b1, 2'b10);

    // 00 hold (q stays 1)
    step_and_check(1'b1, 2'b00);

    // 01 reset (q becomes 0)
    step_and_check(1'b0, 2'b01);

    // 11 toggle (0->1)
    step_and_check(1'b1, 2'b11);

    // 11 toggle (1->0)
    step_and_check(1'b0, 2'b11);

    $display("? JK FF TEST PASSED");
    $stop;
  end

endmodule
