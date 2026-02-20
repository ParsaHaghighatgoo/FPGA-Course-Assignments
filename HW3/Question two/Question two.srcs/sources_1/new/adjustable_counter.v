module adjustable_counter #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,      // synchronous active-high reset
    input  wire [7:0]       div,      // 0..255 => count every (div+1) cycles
    output reg  [WIDTH-1:0] count,
    output wire             ce_out     // optional: expose CE for debug
);

    wire ce;

    // CE generator from Part (a)
    ce_gen_1_to_256 u_ce (
        .clk(clk),
        .rst(rst),
        .div(div),
        .ce(ce)
    );

    // Adjustable-speed counter: same clk, only updates when ce=1
    always @(posedge clk) begin
        if (rst)
            count <= {WIDTH{1'b0}};
        else if (ce)
            count <= count + {{(WIDTH-1){1'b0}}, 1'b1};
    end

    assign ce_out = ce;

endmodule
