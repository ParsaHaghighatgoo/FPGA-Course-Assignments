module button_conditioner #(
    parameter integer DEBOUNCE_CYCLES = 50000  // adjust for your clock (e.g., 50MHz => ~1ms)
)(
    input  wire clk,
    input  wire rst_n,      // active-low reset
    input  wire btn_async,  // raw mechanical button (asynchronous + bouncy)
    output wire btn_event,  // 1-clock pulse on clean rising edge
    output wire btn_level   // debounced level (optional)
);

    // -------------------------------------------------------------------------
    // 1) Two-flop synchronizer: mitigates metastability from async input
    // -------------------------------------------------------------------------
    reg btn_ff1, btn_ff2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_ff1 <= 1'b0;
            btn_ff2 <= 1'b0;
        end else begin
            btn_ff1 <= btn_async;
            btn_ff2 <= btn_ff1;
        end
    end

    // -------------------------------------------------------------------------
    // 2) Debounce logic:
    //    Only change debounced output after input remains stable for N cycles.
    // -------------------------------------------------------------------------
    localparam integer CNT_W = (DEBOUNCE_CYCLES <= 1) ? 1 : $clog2(DEBOUNCE_CYCLES);
    reg [CNT_W-1:0] stable_cnt;
    reg debounced;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounced  <= 1'b0;
            stable_cnt <= {CNT_W{1'b0}};
        end else begin
            if (btn_ff2 == debounced) begin
                // input matches current debounced state -> reset counter
                stable_cnt <= {CNT_W{1'b0}};
            end else begin
                // input differs -> count how long it stays different
                if (DEBOUNCE_CYCLES <= 1) begin
                    debounced <= btn_ff2; // immediate accept if N=1
                end else if (stable_cnt == DEBOUNCE_CYCLES-1) begin
                    debounced  <= btn_ff2;              // accept new stable value
                    stable_cnt <= {CNT_W{1'b0}};
                end else begin
                    stable_cnt <= stable_cnt + 1'b1;
                end
            end
        end
    end

    assign btn_level = debounced;

    // -------------------------------------------------------------------------
    // 3) Edge detection: one clean event per press (rising edge only)
    // -------------------------------------------------------------------------
    reg debounced_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) debounced_d <= 1'b0;
        else        debounced_d <= debounced;
    end

    assign btn_event = debounced & ~debounced_d; // 1-clock pulse on rising edge

endmodule
