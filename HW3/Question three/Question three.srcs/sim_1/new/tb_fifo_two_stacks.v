`timescale 1ns/1ps

module tb_fifo_two_stacks;

    reg clk;
    reg rst;

    reg wr_en;
    reg rd_en;
    reg [7:0] din;

    wire [7:0] dout;
    wire rd_valid;
    wire empty;
    wire full;

    fifo_two_stacks #(.WIDTH(8), .DEPTH(8)) dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .rd_valid(rd_valid),
        .empty(empty),
        .full(full)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task do_write(input [7:0] v);
    begin
        @(posedge clk);
        wr_en <= 1'b1;
        din   <= v;
        @(posedge clk);
        wr_en <= 1'b0;
        din   <= 8'h00;
    end
    endtask

    task do_read;
    begin
        @(posedge clk);
        rd_en <= 1'b1;
        @(posedge clk);
        rd_en <= 1'b0;
    end
    endtask

    initial begin
        wr_en = 0;
        rd_en = 0;
        din   = 0;

        rst = 1;
        repeat(3) @(posedge clk);
        rst = 0;

        // Write values: expect FIFO read order 11,22,33,44,55,66
        do_write(8'd11);
        do_write(8'd22);
        do_write(8'd33);
        do_write(8'd44);

        // Read 2 values (11,22)
        do_read();
        do_read();

        // Write 2 more (55,66)
        do_write(8'd55);
        do_write(8'd66);

        // Read remaining
        repeat(10) do_read();

        repeat(10) @(posedge clk);
        $stop;
    end

    always @(posedge clk) begin
        if (rd_valid) begin
            $display("READ: %0d", dout);
        end
    end

endmodule
