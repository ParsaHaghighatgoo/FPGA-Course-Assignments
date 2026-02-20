// ============================================================
// Multi-Mode CORDIC (Rotation Mode)
//   mode = 0 : circular -> cos/sin (with 1/K pre-scaling)
//   mode = 1 : linear   -> multiply (y ~= a*b)
// Fixed-point: external W=16, Q2.14 by default
// Vivado-friendly, sequential (resource-sharing) architecture
// ============================================================

module cordic_mm_rotlin #(
    parameter integer W      = 16,
    parameter integer FRAC   = 14,
    parameter integer GUARD  = 2,
    parameter integer STEPS  = 14
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   start,
    input  wire                   mode,      // 0=circular, 1=linear

    input  wire signed [W-1:0]    ang_in,    // circular: angle (radians in Q2.14)
    input  wire signed [W-1:0]    in_a,      // linear: multiplicand a (Q2.14)
    input  wire signed [W-1:0]    in_b,      // linear: multiplier   b (Q2.14)

    output reg  signed [W-1:0]    cos_out,
    output reg  signed [W-1:0]    sin_out,
    output reg  signed [W-1:0]    mul_out,

    output wire                   busy,
    output wire                   done
);

    localparam integer EXT = W + GUARD;

    // 1/K for circular mode, quantized to Q2.14 then sign-extended to EXT.
    // 0.607252935 * 2^14 ? 9949
    localparam signed [EXT-1:0] K_INV_Q = 18'sd9949;

    // FSM states
    localparam [1:0] ST_IDLE = 2'd0,
                     ST_RUN  = 2'd1,
                     ST_OUT  = 2'd2;

    reg [1:0] st_q, st_d;
    reg [3:0] i_q,  i_d;

    reg signed [EXT-1:0] x_q, y_q, z_q;
    reg signed [EXT-1:0] x_d, y_d, z_d;

    assign busy = (st_q != ST_IDLE);
    assign done = (st_q == ST_OUT);

    // Sign-extend W->EXT
    function automatic signed [EXT-1:0] sx;
        input signed [W-1:0] v;
        begin
            sx = {{GUARD{v[W-1]}}, v};
        end
    endfunction

    // Saturate EXT->W
    function automatic signed [W-1:0] satW;
        input signed [EXT-1:0] v;
        reg signed [EXT-1:0] hi, lo;
        begin
            hi = $signed({{(EXT-W){1'b0}}, 1'b0, {(W-1){1'b1}}}); // +max
            lo = $signed({{(EXT-W){1'b1}}, 1'b1, {(W-1){1'b0}}}); // -min

            if (v > hi)      satW = {1'b0, {(W-1){1'b1}}};
            else if (v < lo) satW = {1'b1, {(W-1){1'b0}}};
            else             satW = v[W-1:0];
        end
    endfunction

    // atan(2^-k) table in Q2.14 (sign-extended)
    function automatic signed [EXT-1:0] atan_q;
        input [3:0] k;
        begin
            case (k)
                4'd0:  atan_q = 18'sd12868;
                4'd1:  atan_q = 18'sd7596;
                4'd2:  atan_q = 18'sd4014;
                4'd3:  atan_q = 18'sd2037;
                4'd4:  atan_q = 18'sd1023;
                4'd5:  atan_q = 18'sd512;
                4'd6:  atan_q = 18'sd256;
                4'd7:  atan_q = 18'sd128;
                4'd8:  atan_q = 18'sd64;
                4'd9:  atan_q = 18'sd32;
                4'd10: atan_q = 18'sd16;
                4'd11: atan_q = 18'sd8;
                4'd12: atan_q = 18'sd4;
                4'd13: atan_q = 18'sd2;
                default: atan_q = {EXT{1'b0}};
            endcase
        end
    endfunction

    // 2^-k table in Q2.14 (sign-extended)
    function automatic signed [EXT-1:0] step_q;
        input [3:0] k;
        begin
            case (k)
                4'd0:  step_q = 18'sd16384;
                4'd1:  step_q = 18'sd8192;
                4'd2:  step_q = 18'sd4096;
                4'd3:  step_q = 18'sd2048;
                4'd4:  step_q = 18'sd1024;
                4'd5:  step_q = 18'sd512;
                4'd6:  step_q = 18'sd256;
                4'd7:  step_q = 18'sd128;
                4'd8:  step_q = 18'sd64;
                4'd9:  step_q = 18'sd32;
                4'd10: step_q = 18'sd16;
                4'd11: step_q = 18'sd8;
                4'd12: step_q = 18'sd4;
                4'd13: step_q = 18'sd2;
                default: step_q = {EXT{1'b0}};
            endcase
        end
    endfunction

    // shift results
    reg signed [EXT-1:0] x_sh, y_sh;
    reg signed [EXT-1:0] delta;

    // Next-state logic
    always @* begin
        st_d = st_q;
        i_d  = i_q;

        x_d  = x_q;
        y_d  = y_q;
        z_d  = z_q;

        x_sh = $signed(x_q) >>> i_q;
        y_sh = $signed(y_q) >>> i_q;

        case (st_q)
            ST_IDLE: begin
                if (start) begin
                    st_d = ST_RUN;
                    i_d  = 4'd0;

                    if (!mode) begin
                        // circular: start from (1/K, 0), rotate by ang_in
                        x_d = K_INV_Q;
                        y_d = {EXT{1'b0}};
                        z_d = sx(ang_in);
                    end else begin
                        // linear multiply: x=a, y=0, z=b
                        x_d = sx(in_a);
                        y_d = {EXT{1'b0}};
                        z_d = sx(in_b);
                    end
                end
            end

            ST_RUN: begin
                if (!mode) begin
                    delta = atan_q(i_q);
                    if (z_q >= 0) begin
                        x_d = x_q - y_sh;
                        y_d = y_q + x_sh;
                        z_d = z_q - delta;
                    end else begin
                        x_d = x_q + y_sh;
                        y_d = y_q - x_sh;
                        z_d = z_q + delta;
                    end
                end else begin
                    delta = step_q(i_q);
                    if (z_q >= 0) begin
                        y_d = y_q + x_sh;
                        z_d = z_q - delta;
                    end else begin
                        y_d = y_q - x_sh;
                        z_d = z_q + delta;
                    end
                end

                if (i_q == (STEPS-1))
                    st_d = ST_OUT;
                else
                    i_d  = i_q + 4'd1;
            end

            ST_OUT: begin
                st_d = ST_IDLE;
            end

            default: st_d = ST_IDLE;
        endcase
    end

    // Registers + outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st_q    <= ST_IDLE;
            i_q     <= 4'd0;
            x_q     <= {EXT{1'b0}};
            y_q     <= {EXT{1'b0}};
            z_q     <= {EXT{1'b0}};
            cos_out <= {W{1'b0}};
            sin_out <= {W{1'b0}};
            mul_out <= {W{1'b0}};
        end else begin
            st_q <= st_d;
            i_q  <= i_d;
            x_q  <= x_d;
            y_q  <= y_d;
            z_q  <= z_d;

            // Latch results when finishing the last iteration
            if (st_q == ST_RUN && st_d == ST_OUT) begin
                if (!mode) begin
                    cos_out <= satW(x_d);
                    sin_out <= satW(y_d);
                    mul_out <= {W{1'b0}};
                end else begin
                    mul_out <= satW(y_d);
                    cos_out <= {W{1'b0}};
                    sin_out <= {W{1'b0}};
                end
            end
        end
    end

endmodule
