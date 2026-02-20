module tb_div3_lsb_mealy;

    reg clk = 0;
    reg rst = 1;
    reg bit_in = 0;
    wire REM;

    div3_lsb_mealy dut(
        .clk(clk),
        .rst(rst),
        .bit_in(bit_in),
        .REM(REM)
    );

    always #5 clk = ~clk;

    task feed_number;
        input integer value;
        input integer nbits;
        integer i;
        integer expected;
        begin
            // feed LSB first
            for (i = 0; i < nbits; i = i + 1) begin
                bit_in = (value >> i) & 1;
                @(posedge clk);
            end
            expected = (value % 3 != 0); // REM=1 if not divisible
            if (REM !== expected[0]) begin
                $display("FAIL value=%0d expected REM=%0d got REM=%0d", value, expected, REM);
                $stop;
            end else begin
                $display("PASS value=%0d REM=%0d", value, REM);
            end
        end
    endtask

    initial begin
        // reset
        @(posedge clk);
        rst = 1;
        @(posedge clk);
        rst = 0;

        // try a bunch
        feed_number(0, 1);    // 0 divisible
        feed_number(3, 2);    // 11b
        feed_number(6, 3);    // 110b
        feed_number(7, 3);    // 111b
        feed_number(12, 4);   // 1100b
        feed_number(13, 4);   // 1101b
        feed_number(21, 5);   // 10101b
        feed_number(22, 5);   // 10110b

        // brute small range
        begin : brute
            integer v;
            for (v = 0; v < 64; v = v + 1) begin
                // reset between numbers so stream is per-number
                rst = 1; @(posedge clk); rst = 0;
                feed_number(v, 6);
            end
        end

        $display("ALL TESTS PASSED");
        $finish;
    end

endmodule
