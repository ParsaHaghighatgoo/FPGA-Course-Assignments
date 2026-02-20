module q1 (
    input  wire a,
    input  wire b,
    input  wire c,
    input  wire clk,
    output reg  q1,
    output reg  q2
);

wire d1 = a & b;
wire d2 = b | c;

always @(posedge clk) begin
    q1 <= d1;
    q2 <= d2;
end

endmodule
