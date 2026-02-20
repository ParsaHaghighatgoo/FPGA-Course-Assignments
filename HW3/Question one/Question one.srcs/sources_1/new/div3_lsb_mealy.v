module div3_lsb_mealy (
    input  wire clk,
    input  wire rst,      // synchronous active-high reset
    input  wire bit_in,   // incoming bit, LSB first
    output wire REM       // 0 if divisible by 3, 1 otherwise (after this bit is consumed)
);

    // State = {parity, rem[1:0]}
    // parity=0 => next bit weight is 1 (even index: 2^k mod 3 = 1)
    // parity=1 => next bit weight is 2 (odd  index: 2^k mod 3 = 2)
    reg [2:0] state, next_state;

    wire parity = state[2];
    wire [1:0] rem = state[1:0];

    // Compute next remainder based on parity (weight 1 or 2)
    reg [1:0] next_rem;

    always @(*) begin
        // default
        next_rem = rem;

        if (!parity) begin
            // weight = 1: next_rem = (rem + bit_in) mod 3
            case ({rem, bit_in})
                3'b00_0: next_rem = 2'd0;
                3'b00_1: next_rem = 2'd1;
                3'b01_0: next_rem = 2'd1;
                3'b01_1: next_rem = 2'd2;
                3'b10_0: next_rem = 2'd2;
                3'b10_1: next_rem = 2'd0;
                default: next_rem = 2'd0; // not used
            endcase
        end else begin
            // weight = 2: next_rem = (rem + 2*bit_in) mod 3
            // if bit_in=0 => same rem
            // if bit_in=1 => add 2 mod3
            case ({rem, bit_in})
                3'b00_0: next_rem = 2'd0;
                3'b00_1: next_rem = 2'd2;
                3'b01_0: next_rem = 2'd1;
                3'b01_1: next_rem = 2'd0; // 1+2=3 -> 0
                3'b10_0: next_rem = 2'd2;
                3'b10_1: next_rem = 2'd1; // 2+2=4 -> 1
                default: next_rem = 2'd0; // not used
            endcase
        end

        // Toggle parity each consumed bit
        next_state = {~parity, next_rem};
    end

    // Mealy output depends on current state + input via next_rem
    // REM=0 if divisible, else 1
    assign REM = (next_rem == 2'd0) ? 1'b0 : 1'b1;

    // State register
    always @(posedge clk) begin
        if (rst)
            state <= 3'b0_00; // parity=0, rem=0 (start at LSB position)
        else
            state <= next_state;
    end

endmodule
