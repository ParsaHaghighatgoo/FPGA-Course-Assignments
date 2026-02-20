module smart_controller #(
    parameter integer ACTIVE_CYCLES   = 10,
    parameter integer DEBOUNCE_CYCLES = 50000
)(
    input  wire clk,
    input  wire rst_n,      // active-low reset
    input  wire btn_async,  // raw push button
    output reg  appliance_on,
    output reg  fault
);

    // Clean, clock-aligned, single-cycle button event
    wire btn_event;
    wire btn_level; // optional

    button_conditioner #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_btn (
        .clk(clk),
        .rst_n(rst_n),
        .btn_async(btn_async),
        .btn_event(btn_event),
        .btn_level(btn_level)
    );

    // ---------------------------------------------------------
    // State encoding (plain Verilog)
    // ---------------------------------------------------------
    localparam [1:0]
        S_RESET  = 2'b00,
        S_IDLE   = 2'b01,
        S_ACTIVE = 2'b10,
        S_ERROR  = 2'b11;

    reg [1:0] state, next_state;

    // ---------------------------------------------------------
    // Active counter width (Verilog-friendly)
    // ---------------------------------------------------------
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value-1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    localparam integer ACW = (ACTIVE_CYCLES <= 1) ? 1 : clog2(ACTIVE_CYCLES);
    reg [ACW-1:0] active_cnt;

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_RESET;
        else
            state <= next_state;
    end

    // Active counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_cnt <= {ACW{1'b0}};
        end else begin
            if (state != S_ACTIVE) begin
                active_cnt <= {ACW{1'b0}};
            end else begin
                if (active_cnt == ACTIVE_CYCLES-1)
                    active_cnt <= {ACW{1'b0}};
                else
                    active_cnt <= active_cnt + 1'b1;
            end
        end
    end

    // Next-state logic
    always @(*) begin
        next_state = state;

        case (state)
            S_RESET: begin
                // go to Idle on the first clock after reset is released
                next_state = S_IDLE;
            end

            S_IDLE: begin
                if (btn_event)
                    next_state = S_ACTIVE;
            end

            S_ACTIVE: begin
                if (btn_event)
                    next_state = S_ERROR;
                else if (active_cnt == ACTIVE_CYCLES-1)
                    next_state = S_IDLE;
            end

            S_ERROR: begin
                next_state = S_ERROR;
            end

            default: begin
                next_state = S_RESET;
            end
        endcase
    end

    // Outputs (Moore)
    always @(*) begin
        appliance_on = 1'b0;
        fault        = 1'b0;

        case (state)
            S_ACTIVE: begin
                appliance_on = 1'b1;
                fault        = 1'b0;
            end
            S_ERROR: begin
                appliance_on = 1'b0;
                fault        = 1'b1;
            end
            default: begin
                appliance_on = 1'b0;
                fault        = 1'b0;
            end
        endcase
    end

endmodule
