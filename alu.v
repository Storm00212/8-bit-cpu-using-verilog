// ============================================================
// ALU (Arithmetic Logic Unit)
// Performs all arithmetic, logical, and mathematical operations
// ============================================================

`include "instructions.vh"

module alu (
    input wire [7:0]  a,           // First operand (accumulator)
    input wire [7:0]  b,           // Second operand
    input wire [3:0]  operation,   // ALU operation code
    input wire        clk,         // Clock
    input wire        reset,       // Reset
    output reg [7:0]  result,      // ALU result
    output reg [7:0]  flags,       // Status flags [C,Z,N,V,IR, D,B,X]
    output reg        done         // Operation done flag
);

    // Operation codes
    localparam OP_ADD   = 4'h0;
    localparam OP_SUB   = 4'h1;
    localparam OP_MUL   = 4'h2;
    localparam OP_DIV   = 4'h3;
    localparam OP_AND   = 4'h4;
    localparam OP_OR    = 4'h5;
    localparam OP_XOR   = 4'h6;
    localparam OP_NOT   = 4'h7;
    localparam OP_SHL   = 4'h8;
    localparam OP_SHR   = 4'h9;
    localparam OP_ROL   = 4'hA;
    localparam OP_ROR   = 4'hB;
    localparam OP_INC   = 4'hC;
    localparam OP_DEC   = 4'hD;
    localparam OP_CMP   = 4'hE;
    localparam OP_SQRT  = 4'hF;

    // Internal registers
    reg [15:0] mul_reg;           // Multiplication register
    reg [7:0] div_quotient;       // Division quotient
    reg [7:0] div_remainder;      // Division remainder
    reg [7:0] div_counter;        // Division counter
    reg [7:0] sqrt_result;        // Square root result
    reg [7:0] sqrt_counter;       // Square root counter
    reg [3:0] operation_r;       // Registered operation
    reg [7:0] a_reg;              // Registered operand A
    reg [7:0] b_reg;              // Registered operand B
    reg [7:0] result_r;           // Registered result

    // Operation in progress flag
    reg op_in_progress;
    reg [3:0] mul_counter;        // Multiplication counter
    reg [7:0] mul_acc;            // Multiplication accumulator

    // Flags
    wire C, Z, N, V;              // Carry, Zero, Negative, Overflow

    // Calculate flags
    assign C = flags[`FLAG_CARRY];
    assign Z = flags[`FLAG_ZERO];
    assign N = flags[`FLAG_SIGN];
    assign V = flags[`FLAG_OVERFLOW];

    // Scientific calculation approximation using CORDIC-like method
    // Using polynomial approximation for sin/cos
    function [7:0] sin_approx;
        input [7:0] angle;  // Angle in radians * 128
        reg [15:0] angle_sq;
        reg [15:0] angle_quad;
        reg [15:0] term1, term3, term5;
        begin
            // Scale angle to -pi/2 to +pi/2 range
            // Simplified: assume input is in appropriate range
            angle_sq = {angle, 8'h00} * {angle, 8'h00};
            angle_quad = angle_sq * angle_sq;

            // Taylor series: sin(x) = x - x^3/3! + x^5/5! - ...
            // Approximate with first 3 terms, scaled
            term1 = {angle, 8'h00};                                      // x
            term3 = angle_sq * {8'd6, 8'h00} / 16'd5040;                 // x^3/6
            term5 = angle_quad * {8'd12, 8'h00} / 16'd120;               // x^5/120

            sin_approx = term1 - term3 + term5;
        end
    endfunction

    function [7:0] cos_approx;
        input [7:0] angle;
        reg [15:0] angle_sq;
        reg [15:0] angle_quad;
        reg [15:0] term0, term2, term4;
        begin
            angle_sq = {angle, 8'h00} * {angle, 8'h00};
            angle_quad = angle_sq * angle_sq;

            // Taylor series: cos(x) = 1 - x^2/2! + x^4/4! - ...
            term0 = 16'd128;                                            // 1 (scaled)
            term2 = angle_sq / 16'd2;                                   // x^2/2
            term4 = angle_quad / 16'd24;                                // x^4/24

            cos_approx = term0 - term2 + term4;
        end
    endfunction

    // Exponential approximation using series
    function [7:0] exp_approx;
        input [7:0] x;
        reg [15:0] term1, term2, term3, result_acc;
        begin
            // e^x ≈ 1 + x + x^2/2! + x^3/3! + ...
            result_acc = 16'd256;  // Start with 1
            term1 = {x, 8'h00};
            term2 = {x, 8'h00} * {x, 8'h00} / 16'd2;
            term3 = {x, 8'h00} * {x, 8'h00} * {x, 8'h00} / 16'd6;

            result_acc = result_acc + term1 + term2 + term3;
            exp_approx = result_acc[15:8];
        end
    endfunction

    // Natural logarithm approximation
    function [7:0] log_approx;
        input [7:0] x;
        reg [7:0] result;
        integer i;
        begin
            result = 0;
            // ln(1+x) ≈ x - x^2/2 + x^3/3 - ... for |x| < 1
            // For x > 0, normalize and compute
            if (x > 0) begin
                for (i = 0; i < 8; i = i + 1) begin
                    if ((16'd1 << i) < x) begin
                        result = result + 8'd10;  // Approximate
                    end
                end
            end
            log_approx = result;
        end
    endfunction

    // Power function (base^exponent)
    function [7:0] power_approx;
        input [7:0] base;
        input [7:0] exponent;
        reg [15:0] result;
        integer i;
        begin
            result = 16'd256;  // Start with 1
            for (i = 0; i < exponent; i = i + 1) begin
                result = result * {base, 8'h00} / 16'd256;
                if (result > 16'd65280) result = 16'd65280;  // Saturate
            end
            power_approx = result[15:8];
        end
    endfunction

    // Square root approximation
    function [7:0] sqrt_approx;
        input [7:0] x;
        reg [7:0] low, high, mid, mid_sq;
        begin
            low = 0;
            high = 16;
            sqrt_approx = 0;

            // Binary search for square root
            while (high >= low) begin
                mid = (low + high) / 2;
                mid_sq = mid * mid;

                if (mid_sq == x) begin
                    sqrt_approx = mid;
                end else if (mid_sq < x) begin
                    sqrt_approx = mid;
                    low = mid + 1;
                end else begin
                    high = mid - 1;
                end
            end
        end
    endfunction

    // Clock edge operation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            result <= 8'h00;
            flags <= 8'h00;
            done <= 1'b1;
            op_in_progress <= 1'b0;
            mul_reg <= 16'h0000;
            div_quotient <= 8'h00;
            div_remainder <= 8'h00;
            div_counter <= 8'h00;
            sqrt_result <= 8'h00;
            sqrt_counter <= 8'h00;
            mul_counter <= 4'h0;
            mul_acc <= 8'h00;
        end else begin
            if (op_in_progress) begin
                // Multiplication state machine
                if (operation_r == OP_MUL) begin
                    if (mul_counter < 4'd8) begin
                        if (b_reg[mul_counter]) begin
                            mul_acc <= mul_acc + a_reg;
                        end
                        mul_counter <= mul_counter + 1;
                    end else begin
                        result <= mul_acc;
                        flags[`FLAG_ZERO] <= (mul_acc == 8'h00);
                        flags[`FLAG_SIGN] <= mul_acc[7];
                        done <= 1'b1;
                        op_in_progress <= 1'b0;
                    end
                end
                // Division state machine
                else if (operation_r == OP_DIV) begin
                    if (div_counter < 4'd8) begin
                        div_remainder <= {div_remainder[6:0], div_quotient[7]};
                        div_quotient <= div_quotient << 1;
                        div_quotient[0] <= 0;

                        if (div_remainder >= b_reg) begin
                            div_remainder <= div_remainder - b_reg;
                            div_quotient[0] <= 1;
                        end
                        div_counter <= div_counter + 1;
                    end else begin
                        result <= div_quotient;
                        flags[`FLAG_ZERO] <= (div_quotient == 8'h00);
                        flags[`FLAG_SIGN] <= div_quotient[7];
                        done <= 1'b1;
                        op_in_progress <= 1'b0;
                    end
                end
                // Square root state machine
                else if (operation_r == OP_SQRT) begin
                    sqrt_result <= sqrt_approx(a_reg);
                    result <= sqrt_result;
                    flags[`FLAG_ZERO] <= (sqrt_result == 8'h00);
                    flags[`FLAG_SIGN] <= sqrt_result[7];
                    done <= 1'b1;
                    op_in_progress <= 1'b0;
                end
            end else begin
                // Single-cycle operations
                case (operation)
                    OP_ADD: begin
                        {flags[`FLAG_CARRY], result} = {1'b0, a} + {1'b0, b};
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        flags[`FLAG_OVERFLOW] <= (a[7] & b[7] & ~result[7]) | 
                                                  (~a[7] & ~b[7] & result[7]);
                        done <= 1'b1;
                    end

                    OP_SUB: begin
                        {flags[`FLAG_CARRY], result} = {1'b0, a} - {1'b0, b};
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        flags[`FLAG_OVERFLOW] <= (a[7] & ~b[7] & ~result[7]) | 
                                                  (~a[7] & b[7] & result[7]);
                        done <= 1'b1;
                    end

                    OP_MUL: begin
                        mul_reg <= {a, 8'h00};
                        mul_acc <= 8'h00;
                        mul_counter <= 4'h0;
                        operation_r <= operation;
                        a_reg <= a;
                        b_reg <= b;
                        op_in_progress <= 1'b1;
                        done <= 1'b0;
                    end

                    OP_DIV: begin
                        div_quotient <= a;
                        div_remainder <= 8'h00;
                        div_counter <= 4'h0;
                        operation_r <= operation;
                        a_reg <= a;
                        b_reg <= b;
                        op_in_progress <= 1'b1;
                        done <= 1'b0;
                    end

                    OP_AND: begin
                        result <= a & b;
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    OP_OR: begin
                        result <= a | b;
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    OP_XOR: begin
                        result <= a ^ b;
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    OP_NOT: begin
                        result <= ~a;
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    OP_SHL: begin
                        {flags[`FLAG_CARRY], result} = {a, 1'b0};
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    OP_SHR: begin
                        {flags[`FLAG_CARRY], result} = {1'b0, a};
                        result <= {1'b0, a[7:1]};
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    OP_ROL: begin
                        {flags[`FLAG_CARRY], result} = {a[0], a};
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    OP_ROR: begin
                        {flags[`FLAG_CARRY], result} = {a[0], a};
                        result <= {C, a[7:1]};
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    OP_INC: begin
                        result <= a + 1;
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        flags[`FLAG_OVERFLOW] <= (a == 8'h7F);
                        done <= 1'b1;
                    end

                    OP_DEC: begin
                        result <= a - 1;
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        flags[`FLAG_OVERFLOW] <= (a == 8'h80);
                        done <= 1'b1;
                    end

                    OP_CMP: begin
                        {flags[`FLAG_CARRY], result} = {1'b0, a} - {1'b0, b};
                        flags[`FLAG_ZERO] <= (a == b);
                        flags[`FLAG_SIGN] <= result[7];
                        flags[`FLAG_OVERFLOW] <= (a[7] & ~b[7] & ~result[7]) | 
                                                  (~a[7] & b[7] & result[7]);
                        done <= 1'b1;
                    end

                    OP_SQRT: begin
                        operation_r <= operation;
                        a_reg <= a;
                        op_in_progress <= 1'b1;
                        done <= 1'b0;
                    end

                    default: begin
                        done <= 1'b1;
                    end
                endcase
            end
        end
    end

endmodule
