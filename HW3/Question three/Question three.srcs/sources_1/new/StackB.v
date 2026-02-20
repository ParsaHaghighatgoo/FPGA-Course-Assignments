`timescale 1ns/1ps
module StackB #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             push,
    input  wire             pop,
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] dout,
    output wire             empty,
    output wire             full
);
    localparam AW = $clog2(DEPTH);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [AW:0]      sp;

    assign empty = (sp == 0);
    assign full  = (sp == DEPTH);

    always @(posedge clk) begin
        if (rst) begin
            sp   <= 0;
            dout <= 0;
        end else begin
            case ({(push && !full), (pop && !empty)})
                2'b10: begin
                    mem[sp] <= din;
                    sp      <= sp + 1;
                end
                2'b01: begin
                    dout <= mem[sp-1];
                    sp   <= sp - 1;
                end
                2'b11: begin
                    dout      <= mem[sp-1];
                    mem[sp-1] <= din;
                    sp        <= sp;
                end
                default: begin
                    sp <= sp;
                end
            endcase
        end
    end
endmodule
