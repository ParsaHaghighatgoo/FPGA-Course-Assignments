module slow_counter (
    input  wire       clk,
    input  wire       rst,   // synchronous
    input  wire       ce,
    output reg [7:0]  q
);
    always @(posedge clk) begin
        if (rst) q <= 8'd0;
        else if (ce) q <= q + 8'd1;
    end
endmodule
