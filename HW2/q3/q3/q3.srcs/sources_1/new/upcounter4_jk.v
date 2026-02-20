module upcounter4_jk (
    input  wire clk,
    input  wire rst,
    output wire [3:0] out
);
wire qa, qb, qc, qd;

wire t0 = 1'b1;
wire t1 = qa;
wire t2 = qa & qb;
wire t3 = qa & qb & qc;

jk_ff FFA (.clk(clk), .rst(rst), .j(t0), .k(t0), .q(qa), .qbar());
jk_ff FFB (.clk(clk), .rst(rst), .j(t1), .k(t1), .q(qb), .qbar());
jk_ff FFC (.clk(clk), .rst(rst), .j(t2), .k(t2), .q(qc), .qbar());
jk_ff FFD (.clk(clk), .rst(rst), .j(t3), .k(t3), .q(qd), .qbar());

assign out = {qd, qc, qb, qa};

endmodule
