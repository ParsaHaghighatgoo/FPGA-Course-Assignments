`timescale 1ns/1ps

module tb_q2_5_add_abs_err;

    reg  signed [31:0] a_q16_16;
    reg  signed [31:0] b_q16_16;

    wire signed [15:0] a_q2_5;
    wire signed [15:0] b_q2_5;
    wire signed [15:0] sum_q2_5;
    wire signed [15:0] true_sum_q2_5;
    wire signed [15:0] abs_err_q2_5;

    q2_5_add_abs_err dut (
        .a_q16_16(a_q16_16),
        .b_q16_16(b_q16_16),
        .a_q2_5(a_q2_5),
        .b_q2_5(b_q2_5),
        .sum_q2_5(sum_q2_5),
        .true_sum_q2_5(true_sum_q2_5),
        .abs_err_q2_5(abs_err_q2_5)
    );

    real ra, rb, rsum, rtrue, rerr;

    task show;
        begin
            // Q2.5 scaling = /32
            ra    = a_q2_5 / 32.0;
            rb    = b_q2_5 / 32.0;
            rsum  = sum_q2_5 / 32.0;
            rtrue = true_sum_q2_5 / 32.0;
            rerr  = abs_err_q2_5 / 32.0;

            $display("--------------------------------------------------");
            $display("a_q16_16=%0d   b_q16_16=%0d", a_q16_16, b_q16_16);
            $display("a_q2_5        = %0d  -> %f", a_q2_5, ra);
            $display("b_q2_5        = %0d  -> %f", b_q2_5, rb);
            $display("sum_q2_5      = %0d  -> %f", sum_q2_5, rsum);
            $display("true_sum_q2_5 = %0d  -> %f", true_sum_q2_5, rtrue);
            $display("abs_err_q2_5  = %0d  -> %f", abs_err_q2_5, rerr);
        end
    endtask

    initial begin
        // Test 1: Part (c) values
        // 8.75 -> Q16.16 = 8.75 * 65536 = 573440
        // 0.000525 -> Q16.16 ~ 0.000525 * 65536 = 34.4064 -> 34
        a_q16_16 = 32'sd573440;
        b_q16_16 = 32'sd34;
        #10;
        show();

        // Test 2 (optional): b = 0.05 so it becomes visible in Q2.5
        // 0.05 * 65536 = 3276.8 -> 3277
        b_q16_16 = 32'sd3277;
        #10;
        show();

        $stop;
    end

endmodule
