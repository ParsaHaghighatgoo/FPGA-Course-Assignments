module ce_gen_1_to_256 (
    input  wire       clk,
    input  wire       rst,      // synchronous active-high reset
    input  wire [7:0] div,      // 0..255  => enable every (div+1) cycles
    output reg        ce        // 1-clock-wide enable pulse
);
    reg [7:0] cnt;

    always @(posedge clk) begin
        if (rst) begin
            cnt <= 8'd0;
            ce  <= 1'b0;
        end else begin
            if (cnt == div) begin
                cnt <= 8'd0;
                ce  <= 1'b1;   // pulse for exactly one clk
            end else begin
                cnt <= cnt + 8'd1;
                ce  <= 1'b0;
            end
        end
    end
endmodule
