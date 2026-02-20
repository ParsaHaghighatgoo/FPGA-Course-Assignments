`timescale 1ns/1ps
module fifo_two_stacks #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             wr_en,
    input  wire             rd_en,
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] dout,
    output reg              rd_valid,
    output wire             empty,
    output wire             full
);

    // stack signals (REGISTERED, single driver)
    reg             pushA, popA, pushB, popB;
    reg [WIDTH-1:0] dinA, dinB;
    wire [WIDTH-1:0] doutA, doutB;
    wire            emptyA, fullA, emptyB, fullB;

    StackA #(.WIDTH(WIDTH), .DEPTH(DEPTH)) uA (
        .clk(clk), .rst(rst),
        .push(pushA), .pop(popA),
        .din(dinA), .dout(doutA),
        .empty(emptyA), .full(fullA)
    );

    StackB #(.WIDTH(WIDTH), .DEPTH(DEPTH)) uB (
        .clk(clk), .rst(rst),
        .push(pushB), .pop(popB),
        .din(dinB), .dout(doutB),
        .empty(emptyB), .full(fullB)
    );

    // FIFO occupancy count enforces total depth = DEPTH
    localparam CW = $clog2(DEPTH+1);
    reg [CW-1:0] count;

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    // FSM
    localparam [1:0]
        S_IDLE       = 2'd0,
        S_XFER_POPA  = 2'd1,
        S_XFER_PUSHB = 2'd2,
        S_READ_CAP   = 2'd3;

    reg [1:0] state;
    reg [WIDTH-1:0] xfer_data;

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            count    <= 0;
            dout     <= 0;
            rd_valid <= 0;

            pushA <= 0; popA <= 0; dinA <= 0;
            pushB <= 0; popB <= 0; dinB <= 0;

            xfer_data <= 0;
        end else begin
            // defaults each cycle
            pushA <= 0; popA <= 0;
            pushB <= 0; popB <= 0;
            dinA  <= din;
            dinB  <= xfer_data;

            rd_valid <= 1'b0;

            // do enqueue/dequeue bookkeeping only when truly accepted
            // (we can accept wr and rd in same cycle in IDLE if no transfer needed)

            case (state)
                S_IDLE: begin
                    // write
                    if (wr_en && !full) begin
                        pushA <= 1'b1;
                        dinA  <= din;
                        count <= count + 1;
                    end

                    // read
                    if (rd_en && !empty) begin
                        if (!emptyB) begin
                            popB  <= 1'b1;
                            count <= count - 1;
                            state <= S_READ_CAP;
                        end else begin
                            // need transfer first (A must have data because FIFO not empty)
                            state <= S_XFER_POPA;
                        end
                    end
                end

                // pop from A (produces doutA next cycle)
                S_XFER_POPA: begin
                    if (!emptyA && !fullB) begin
                        popA  <= 1'b1;
                        state <= S_XFER_PUSHB;
                    end else begin
                        state <= S_IDLE;
                    end
                end

                // capture doutA and push into B; loop until A empty
                S_XFER_PUSHB: begin
                    xfer_data <= doutA;
                    pushB     <= 1'b1;
                    dinB      <= doutA;

                    if (!emptyA) state <= S_XFER_POPA;
                    else         state <= S_IDLE;
                end

                // capture popped data from B
                S_READ_CAP: begin
                    dout     <= doutB;
                    rd_valid <= 1'b1;
                    state    <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
