module jk_ff (
    input  wire clk,
    input  wire rst,     // async reset (active-high)
    input  wire j,
    input  wire k,
    output reg  q,
    output wire qbar
);
assign qbar = ~q;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        q <= 1'b0;
    end else begin
        case ({j,k})
            2'b00: q <= q;      // hold
            2'b01: q <= 1'b0;   // reset
            2'b10: q <= 1'b1;   // set
            2'b11: q <= ~q;     // toggle
        endcase
    end
end

endmodule
