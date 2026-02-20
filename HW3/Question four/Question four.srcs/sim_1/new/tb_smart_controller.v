`timescale 1ns/1ps

module tb_smart_controller;

    // ------------------------------------------------------------
    // Clock: 100 MHz (period = 10 ns)
    // ------------------------------------------------------------
    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // DUT I/O
    // ------------------------------------------------------------
    reg  rst_n;
    reg  btn_async;

    wire appliance_on;
    wire fault;

    // ------------------------------------------------------------
    // Instantiate DUT
    // NOTE: Use small DEBOUNCE_CYCLES for SIMULATION only
    // ------------------------------------------------------------
    smart_controller #(
        .ACTIVE_CYCLES(10),
        .DEBOUNCE_CYCLES(3)      // small so btn_event triggers quickly in sim
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .btn_async(btn_async),
        .appliance_on(appliance_on),
        .fault(fault)
    );

    // ------------------------------------------------------------
    // Helpful tasks
    // ------------------------------------------------------------

    // Hold button stable HIGH long enough to pass debounce
    task press_clean;
        input integer hold_cycles; // number of clk cycles to hold high
        integer i;
        begin
            btn_async = 1'b1;
            for (i = 0; i < hold_cycles; i = i + 1) begin
                @(posedge clk);
            end
            btn_async = 1'b0;
            // wait a couple cycles after release
            @(posedge clk);
            @(posedge clk);
        end
    endtask

    // Simulate bounce: rapid toggles, then stable high long enough to debounce
    task press_bouncy_then_stable;
        input integer stable_cycles;
        begin
            // "bounce" (fast toggles not aligned to clk)
            #3  btn_async = 1'b1;
            #4  btn_async = 1'b0;
            #2  btn_async = 1'b1;
            #3  btn_async = 1'b0;
            #2  btn_async = 1'b1;

            // now hold stable long enough for debouncer
            repeat (stable_cycles) @(posedge clk);

            // release
            btn_async = 1'b0;
            @(posedge clk);
            @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------
    initial begin
        // init
        rst_n     = 1'b0;
        btn_async = 1'b0;

        // apply reset for a few cycles
        repeat (3) @(posedge clk);
        rst_n = 1'b1;  // release reset

        // wait a couple cycles -> should go to IDLE
        repeat (2) @(posedge clk);

        // ========================================================
        // 1) IDLE press with bounce -> should generate ONE btn_event
        //    and enter ACTIVE
        // ========================================================
        press_bouncy_then_stable(4);  // stable 4 cycles > DEBOUNCE_CYCLES(3)

        // wait 2 cycles, should be in ACTIVE now (appliance_on=1)
        repeat (2) @(posedge clk);

        // ========================================================
        // 2) While in ACTIVE, press again (clean) -> should go ERROR
        // ========================================================
        press_clean(4);  // hold high long enough for debounce -> btn_event

        // wait a few cycles to observe ERROR holding
        repeat (5) @(posedge clk);

        // ========================================================
        // 3) Reset should clear ERROR -> back to IDLE
        // ========================================================
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        repeat (3) @(posedge clk);

        // done
        $finish;
    end

endmodule
