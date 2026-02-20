`timescale 1ns/1ps

module ripple_carry_adder4_tb;

reg  [3:0] a, b;
reg        cin;
wire [3:0] s;
wire       cout;

ripple_carry_adder4 dut (
    .a(a), .b(b), .cin(cin),
    .s(s), .cout(cout)
);

initial begin
    // test 1: 3 + 5 = 8
    a = 4'd3;  b = 4'd5;  cin = 1'b0;
    #10;

    // test 2: 9 + 6 = 15
    a = 4'd9;  b = 4'd6;  cin = 1'b0;
    #10;

    // test 3: 15 + 1 = 16 -> s=0, cout=1
    a = 4'd15; b = 4'd1;  cin = 1'b0;
    #10;

    // test 4: 7 + 8 + cin(1) = 16 -> s=0, cout=1
    a = 4'd7;  b = 4'd8;  cin = 1'b1;
    #10;

    $stop;
end

endmodule
