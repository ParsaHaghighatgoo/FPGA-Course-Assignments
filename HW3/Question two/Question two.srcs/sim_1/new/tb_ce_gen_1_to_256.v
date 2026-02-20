`timescale 1ns/1ps

module tb_ce_gen_1_to_256;

    reg clk = 0;
    reg rst = 1;
    reg [7:0] div = 0;

    wire ce;
    wire [7:0] q;

    // DUT
    ce_gen_1_to_256 dut (
        .clk(clk),
        .rst(rst),
        .div(div),
        .ce(ce)
    );

    // Target module driven by CE (same clk)
    slow_counter u_cnt (
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .q(q)
    );

    // 100 MHz clock (period 10ns)
    always #5 clk = ~clk;

    // Measure CE spacing and validate
    task check_div;
        input [7:0] d;
        integer cycles_between;
        integer expected;
        integer pulses;
        reg [7:0] q_start;
        begin
            div = d;
            expected = d + 1;

            // reset to align measurement
            rst = 1;
            @(posedge clk);
            rst = 0;

            // wait for first CE pulse (start point)
            while (ce !== 1'b1) @(posedge clk);

            pulses = 0;
            q_start = q;

            // check next few pulses spacing
            repeat (5) begin
                pulses = pulses + 1;

                // count cycles until next CE pulse
                cycles_between = 0;
                @(posedge clk); // move past current pulse edge
                while (ce !== 1'b1) begin
                    cycles_between = cycles_between + 1;
                    @(posedge clk);
                end

                // cycles_between counts cycles where ce==0
                // so total period in cycles = cycles_between + 1
                if ((cycles_between + 1) != expected) begin
                    $display("FAIL div=%0d expected period=%0d got=%0d",
                             d, expected, (cycles_between + 1));
                    $stop;
                end
            end

            // After 5 additional pulses, q should have incremented 5 times
            if (q != (q_start + 5)) begin
                $display("FAIL slow_counter div=%0d expected q increase by 5, got q_start=%0d q=%0d",
                         d, q_start, q);
                $stop;
            end

            $display("PASS div=%0d => CE every %0d cycles; slow_counter increments correctly.", d, expected);
        end
    endtask

    initial begin
        // global reset
        @(posedge clk);
        rst = 1;
        @(posedge clk);
        rst = 0;

        // test a few key cases
        check_div(8'd0);    // fastest: every 1 cycle
        check_div(8'd1);    // every 2 cycles
        check_div(8'd2);    // every 3 cycles
        check_div(8'd9);    // every 10 cycles
        check_div(8'd255);  // slowest: every 256 cycles

        $display("ALL CE TESTS PASSED");
        $finish;
    end

endmodule
