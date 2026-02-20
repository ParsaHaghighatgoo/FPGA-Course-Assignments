`timescale 1ns/1ps
// ============================================================
// Pure Verilog-2001 Testbench
// ============================================================

module tb_cordic_mm_rotlin;

    // Match DUT params
    parameter integer W     = 16;
    parameter integer FRAC  = 14;
    parameter integer GUARD = 2;
    parameter integer STEPS = 14;

    // DUT I/O
    reg                   clk;
    reg                   rst_n;
    reg                   start;
    reg                   mode;      // 0=circular, 1=linear
    reg  signed [W-1:0]   ang_in;
    reg  signed [W-1:0]   in_a;
    reg  signed [W-1:0]   in_b;

    wire signed [W-1:0]   cos_out;
    wire signed [W-1:0]   sin_out;
    wire signed [W-1:0]   mul_out;
    wire                  busy;
    wire                  done;

    cordic_mm_rotlin #(
        .W(W), .FRAC(FRAC), .GUARD(GUARD), .STEPS(STEPS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .mode(mode),
        .ang_in(ang_in),
        .in_a(in_a),
        .in_b(in_b),
        .cos_out(cos_out),
        .sin_out(sin_out),
        .mul_out(mul_out),
        .busy(busy),
        .done(done)
    );

    // ------------------------------------------------------------
    // Clock: 100 MHz (10 ns period)
    // ------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Real-valued globals 
    // ------------------------------------------------------------
    real lsb;
    real tol;

    // Scratch reals for checking
    real got_r;
    real exp_r;

    // ------------------------------------------------------------
    // Fixed-point helpers 
    // ------------------------------------------------------------
    function signed [W-1:0] to_fixed;
        input real x;
        integer v;
        begin
            v = $rtoi(x * (1<<FRAC));
            // clamp to signed W range
            if (v >  ((1<<(W-1)) - 1)) v =  ((1<<(W-1)) - 1);
            if (v < -(1<<(W-1))      ) v = -(1<<(W-1));
            to_fixed = v[W-1:0];
        end
    endfunction

    function real from_fixed;
        input signed [W-1:0] v;
        begin
            from_fixed = $itor(v) / (1<<FRAC);
        end
    endfunction

    // ------------------------------------------------------------
    // Pulse start for 1 cycle
    // ------------------------------------------------------------
    task pulse_start;
        begin
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;
        end
    endtask

    // ------------------------------------------------------------
    // Wait for done pulse (done asserted in ST_OUT for 1 cycle)
    // ------------------------------------------------------------
    task wait_done;
        begin
            // Wait until done goes high
            while (done !== 1'b1) begin
                @(posedge clk);
            end
            // Move one more clock so outputs are stable for viewing
            @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------
    // Check task 
    // ------------------------------------------------------------
    task check_close;
        input integer test_id;
        input real got;
        input real exp;
        input real tol_in;
        real err;
        begin
            err = got - exp;
            if (err < 0.0) err = -err;

            if (err <= tol_in) begin
                $display("[PASS] id=%0d got=%f exp=%f err=%e", test_id, got, exp, err);
            end else begin
                $display("[FAIL] id=%0d got=%f exp=%f err=%e tol=%e", test_id, got, exp, err, tol_in);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Run one circular test: angle th (radians)
    // test_id base: provide unique id numbers
    // ------------------------------------------------------------
    task run_circ;
        input integer base_id;
        input real th;
        begin
            mode  = 1'b0;
            ang_in = to_fixed(th);
            in_a   = 0;
            in_b   = 0;

            pulse_start();
            wait_done();

            // cos
            got_r = from_fixed(cos_out);
            exp_r = $cos(th);
            check_close(base_id + 0, got_r, exp_r, tol);

            // sin
            got_r = from_fixed(sin_out);
            exp_r = $sin(th);
            check_close(base_id + 1, got_r, exp_r, tol);
        end
    endtask

    // ------------------------------------------------------------
    // Run one multiply test: a*b (linear mode)
    // test_id: provide unique id
    // ------------------------------------------------------------
    task run_mul;
        input integer test_id;
        input real a;
        input real b;
        begin
            mode  = 1'b1;
            in_a  = to_fixed(a);
            in_b  = to_fixed(b);
            ang_in = 0;

            pulse_start();
            wait_done();

            got_r = from_fixed(mul_out);
            exp_r = a * b;
            check_close(test_id, got_r, exp_r, tol);
        end
    endtask

    // ------------------------------------------------------------
    // Main stimulus
    // ------------------------------------------------------------
    initial begin
        // init
        rst_n = 1'b0;
        start = 1'b0;
        mode  = 1'b0;
        ang_in = 0;
        in_a   = 0;
        in_b   = 0;

        // tolerance: 10 LSB
        lsb = 1.0 / (1<<FRAC);
        tol = 10.0 * lsb;

        // reset
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        $display("==================================================");
        $display("TB start: W=%0d FRAC=%0d STEPS=%0d", W, FRAC, STEPS);
        $display("LSB=%e  TOL(10LSB)=%e", lsb, tol);
        $display("Note: circular valid range ~[-pi/2,+pi/2] without quadrant correction");
        $display("==================================================");

        // ----------------------------
        // Circular tests (ids 100+)
        // ----------------------------
        run_circ(100,  0.0);
        run_circ(110,  0.3);
        run_circ(120, -0.7);
        run_circ(130,  1.0);

        // ----------------------------
        // Linear multiply tests (ids 200+)
        // ----------------------------
        run_mul(200,  0.50,  0.25);
        run_mul(210, -0.75,  0.60);
        run_mul(220,  0.90, -0.40);
        run_mul(230, -0.33, -0.66);

        $display("TB finished.");
        #50;
        $finish;
    end

endmodule
