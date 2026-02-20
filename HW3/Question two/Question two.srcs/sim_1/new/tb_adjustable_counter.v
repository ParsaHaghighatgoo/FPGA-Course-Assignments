`timescale 1ns/1ps

module tb_adjustable_counter;

    // ---------------------------
    // DUT inputs
    // ---------------------------
    reg clk;
    reg rst;
    reg [7:0] div;

    // DUT outputs
    wire [7:0] count;
    wire ce_out;

    // ---------------------------
    // Instantiate DUT
    // ---------------------------
    adjustable_counter #(.WIDTH(8)) dut (
        .clk(clk),
        .rst(rst),
        .div(div),
        .count(count),
        .ce_out(ce_out)
    );

    // ---------------------------
    // Clock: 100 MHz (10 ns period)
    // ---------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ---------------------------
    // Helper: run N clock cycles
    // ---------------------------
    task run_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // ---------------------------
    // Scoreboard: verify count changes only on CE
    // ---------------------------
    reg [7:0] count_prev;

    always @(posedge clk) begin
        if (rst) begin
            count_prev <= 8'd0;
        end else begin
            // If CE is 1, count must increment by 1
            if (ce_out) begin
                if (count !== (count_prev + 8'd1)) begin
                    $display("FAIL @%0t: CE=1 but count did not increment correctly. prev=%0d now=%0d",
                             $time, count_prev, count);
                    $stop;
                end
            end else begin
                // If CE is 0, count must hold
                if (count !== count_prev) begin
                    $display("FAIL @%0t: CE=0 but count changed. prev=%0d now=%0d",
                             $time, count_prev, count);
                    $stop;
                end
            end

            count_prev <= count;
        end
    end

    // ---------------------------
    // Stimulus
    // ---------------------------
    initial begin
        // Start clean: define all inputs
        rst = 1'b1;
        div = 8'd0;  // default
        count_prev = 8'd0;

        // Hold reset long enough to clear everything
        run_cycles(5);
        rst = 1'b0;

        // ---- Case 1: div=0 => CE every 1 cycle (fastest) ----
        div = 8'd0;
        run_cycles(25);

        // ---- Case 2: div=1 => CE every 2 cycles ----
        div = 8'd1;
        run_cycles(40);

        // ---- Case 3: div=2 => CE every 3 cycles ----
        div = 8'd2;
        run_cycles(60);

        // ---- Case 4: div=9 => CE every 10 cycles ----
        div = 8'd9;
        run_cycles(120);

        // ---- Case 5: div=255 => CE every 256 cycles (slowest) ----
        // We simulate enough cycles to observe a couple pulses.
        div = 8'd255;
        run_cycles(600);

        $display("ALL TESTS PASSED");
        $finish;
    end

endmodule
