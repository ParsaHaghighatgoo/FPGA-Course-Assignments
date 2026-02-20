`timescale 1ns/1ps

module full_adder_tb;

  reg a, b, ci;
  wire s, co;

  // Instantiate the full adder
  full_adder dut (
    .a(a),
    .b(b),
    .ci(ci),
    .s(s),
    .co(co)
  );

  initial begin
    // Test all input combinations

    a = 0; b = 0; ci = 0;  #10;   // 0 + 0 + 0 = 0
    a = 0; b = 0; ci = 1;  #10;   // 0 + 0 + 1 = 1
    a = 0; b = 1; ci = 0;  #10;   // 0 + 1 + 0 = 1
    a = 0; b = 1; ci = 1;  #10;   // 0 + 1 + 1 = 2
    a = 1; b = 0; ci = 0;  #10;   // 1 + 0 + 0 = 1
    a = 1; b = 0; ci = 1;  #10;   // 1 + 0 + 1 = 2
    a = 1; b = 1; ci = 0;  #10;   // 1 + 1 + 0 = 2
    a = 1; b = 1; ci = 1;  #10;   // 1 + 1 + 1 = 3

    $stop;
  end

endmodule
