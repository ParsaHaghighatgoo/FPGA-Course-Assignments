module upcounter4_rtl (
    input  wire clk,
    input  wire rst,          // async reset (active-high)
    output reg  [3:0] out
);

always @(posedge clk or posedge rst) begin
    if (rst)
        out <= 4'b0000;
    else
        out <= out + 1'b1;
end

endmodule
