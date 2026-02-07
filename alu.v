// ============================================================================
// ALU (Arithmetic Logic Unit)
// Performs all arithmetic, logical, and mathematical operations
// ============================================================================
// 
// The ALU is the computational heart of the CPU. It receives operands from
// the register file and performs operations based on the operation code
// provided by the control unit. The ALU also calculates and outputs flags
// that indicate the result characteristics (zero, negative, carry, overflow).
// 
// Architecture Overview:
// - 8-bit data path for operands and results
// - Support for both single-cycle and multi-cycle operations
// - Built-in flag calculation for all operations
// - Scientific calculation approximations using series expansions
// ============================================================================

`include "instructions.vh"

module alu (
    // Clock and reset signals
    input wire clk,           // System clock - all operations are synchronous
    input wire reset,         // Asynchronous reset - clears all registers
    
    // Operand inputs
    input wire [7:0] a,       // First operand (typically the accumulator)
    input wire [7:0] b,       // Second operand (from data bus or register)
    
    // Control signals
    input wire [3:0] operation,  // ALU operation code (4 bits, 16 possible ops)
    
    // Outputs
    output reg [7:0] result, // 8-bit result of the operation
    output reg [7:0] flags,   // Status flags register
    output reg done           // Operation completion flag
);

    // =========================================================================
    // Operation Code Definitions
    // =========================================================================
    // These localparam values map human-readable operation names to the
    // 4-bit codes used internally by the ALU. This allows for clearer
    // case statements and easier maintenance.
    
    localparam OP_ADD   = 4'h0;   // Addition operation
    localparam OP_SUB   = 4'h1;   // Subtraction operation
    localparam OP_MUL   = 4'h2;   // Multiplication operation
    localparam OP_DIV   = 4'h3;   // Division operation
    localparam OP_AND   = 4'h4;   // Bitwise AND operation
    localparam OP_OR    = 4'h5;   // Bitwise OR operation
    localparam OP_XOR   = 4'h6;   // Bitwise XOR operation
    localparam OP_NOT   = 4'h7;   // Bitwise NOT (complement) operation
    localparam OP_SHL   = 4'h8;   // Shift Left operation
    localparam OP_SHR   = 4'h9;   // Shift Right operation
    localparam OP_ROL   = 4'hA;   // Rotate Left operation
    localparam OP_ROR   = 4'hB;   // Rotate Right operation
    localparam OP_INC   = 4'hC;   // Increment operation
    localparam OP_DEC   = 4'hD;   // Decrement operation
    localparam OP_CMP   = 4'hE;   // Compare operation
    localparam OP_SQRT  = 4'hF;   // Square Root operation

    // =========================================================================
    // Internal Registers
    // =========================================================================
    // These registers are used for multi-cycle operations that cannot
    // complete in a single clock cycle. They store intermediate results
    // and state information during the operation.
    
    // Multiplication: stores partial products and accumulated results
    reg [15:0] mul_reg;           // 16-bit register for multiplication accumulation
    reg [7:0] mul_acc;            // Accumulator for multiplication result
    reg [3:0] mul_counter;        // Counter for 8 iterations (one per bit)
    
    // Division: stores quotient, remainder, and iteration state
    reg [7:0] div_quotient;       // Result of division (quotient)
    reg [7:0] div_remainder;     // Remainder after division
    reg [7:0] div_counter;       // Counter for 8 iterations
    reg [3:0] operation_r;      // Registered operation for state machine
    reg [7:0] a_reg;             // Registered operand A
    reg [7:0] b_reg;             // Registered operand B
    
    // Square root: stores calculation state
    reg [7:0] sqrt_result;        // Result of square root calculation
    reg [7:0] sqrt_counter;      // Counter for approximation iterations
    
    // Result register for pipelining
    reg [7:0] result_r;          // Registered result output

    // =========================================================================
    // Operation Status Signals
    // =========================================================================
    // This signal indicates whether a multi-cycle operation is in progress.
    // When set, the ALU is in the middle of executing an operation that
    // requires multiple clock cycles (like multiplication or division).
    reg op_in_progress;

    // =========================================================================
    // Flag Bit Extraction
    // =========================================================================
    // These wires extract individual flag bits from the flags register
    // for easier use in calculations and debugging.
    
    wire C, Z, N, V;             // Carry, Zero, Negative, Overflow flags
    
    // Extract flag bits from the flags register
    assign C = flags[`FLAG_CARRY];
    assign Z = flags[`FLAG_ZERO];
    assign N = flags[`FLAG_SIGN];
    assign V = flags[`FLAG_OVERFLOW];

    // =========================================================================
    // Scientific Calculation Functions
    // =========================================================================
    // These functions implement polynomial approximations for scientific
    // calculations. They use Taylor series expansions and other numerical
    // methods to approximate common mathematical functions.
    
    // -------------------------------------------------------------------------
    // Sine Approximation
    // -------------------------------------------------------------------------
    // Uses Taylor series expansion: sin(x) = x - x^3/3! + x^5/5! - x^7/7! + ...
    // This implementation uses the first three terms of the series for
    // a good balance between accuracy and computational complexity.
    // 
    // Input: angle - scaled angle in radians (multiplied by 128)
    // Output: sin(angle) approximation scaled to 8 bits
    function [7:0] sin_approx;
        input [7:0] angle;        // Input angle scaled by 128
        
        // Local variables for intermediate calculations
        reg [15:0] angle_sq;       // angle^2
        reg [15:0] angle_quad;    // angle^4
        reg [15:0] term1, term3, term5;  // Taylor series terms
        
        begin
            // Calculate powers of the angle
            // Scale up by 256 (shift left 8 bits) for fractional precision
            angle_sq = {angle, 8'h00} * {angle, 8'h00};
            angle_quad = angle_sq * angle_sq;
            
            // Taylor series terms
            // term1 = x (scaled)
            // term3 = x^3/6 (approximation of x^3/3!)
            // term5 = x^5/120 (approximation of x^5/5!)
            term1 = {angle, 8'h00};                                      // x
            term3 = angle_sq * {8'd6, 8'h00} / 16'd5040;                 // x^3/6
            term5 = angle_quad * {8'd12, 8'h00} / 16'd120;               // x^5/120
            
            // Calculate sin approximation using series
            sin_approx = term1 - term3 + term5;
        end
    endfunction

    // -------------------------------------------------------------------------
    // Cosine Approximation
    // -------------------------------------------------------------------------
    // Uses Taylor series expansion: cos(x) = 1 - x^2/2! + x^4/4! - x^6/6! + ...
    // Similar to sine, uses first three terms for approximation.
    //
    // Input: angle - scaled angle in radians
    // Output: cos(angle) approximation
    function [7:0] cos_approx;
        input [7:0] angle;
        reg [15:0] angle_sq;
        reg [15:0] angle_quad;
        reg [15:0] term0, term2, term4;
        begin
            angle_sq = {angle, 8'h00} * {angle, 8'h00};
            angle_quad = angle_sq * angle_sq;
            
            // Taylor series terms for cosine
            // term0 = 1 (scaled to 256)
            // term2 = x^2/2
            // term4 = x^4/24
            term0 = 16'd128;                                            // 1 (scaled)
            term2 = angle_sq / 16'd2;                                   // x^2/2
            term4 = angle_quad / 16'd24;                                // x^4/24
            
            cos_approx = term0 - term2 + term4;
        end
    endfunction

    // -------------------------------------------------------------------------
    // Exponential Approximation
    // -------------------------------------------------------------------------
    // Uses Taylor series: e^x = 1 + x + x^2/2! + x^3/3! + x^4/4! + ...
    // This approximates e^x for values of x in a reasonable range.
    //
    // Input: x - exponent value
    // Output: e^x approximation
    function [7:0] exp_approx;
        input [7:0] x;
        reg [15:0] term1, term2, term3, result_acc;
        begin
            // Start with 1 (scaled to 256)
            result_acc = 16'd256;
            
            // First few terms of Taylor series
            term1 = {x, 8'h00};
            term2 = {x, 8'h00} * {x, 8'h00} / 16'd2;
            term3 = {x, 8'h00} * {x, 8'h00} * {x, 8'h00} / 16'd6;
            
            // Sum all terms
            result_acc = result_acc + term1 + term2 + term3;
            exp_approx = result_acc[15:8];
        end
    endfunction

    // -------------------------------------------------------------------------
    // Natural Logarithm Approximation
    // -------------------------------------------------------------------------
    // Uses series expansion: ln(1+x) = x - x^2/2 + x^3/3 - ... for |x| < 1
    // This is a simplified implementation that normalizes the input.
    //
    // Input: x - value to take natural log of
    // Output: ln(x) approximation
    function [7:0] log_approx;
        input [7:0] x;
        reg [7:0] result;
        integer i;
        begin
            result = 0;
            // Normalize and compute using iterative approach
            if (x > 0) begin
                for (i = 0; i < 8; i = i + 1) begin
                    if ((16'd1 << i) < x) begin
                        result = result + 8'd10;  // Approximate contribution
                    end
                end
            end
            log_approx = result;
        end
    endfunction

    // -------------------------------------------------------------------------
    // Power Function (Base^Exponent)
    // -------------------------------------------------------------------------
    // Calculates base raised to the power of exponent using repeated
    // multiplication with saturation to prevent overflow.
    //
    // Input: base - base value
    //        exponent - power to raise base to
    // Output: base^exponent approximation
    function [7:0] power_approx;
        input [7:0] base;
        input [7:0] exponent;
        reg [15:0] result;
        integer i;
        begin
            result = 16'd256;  // Start with 1 (scaled)
            for (i = 0; i < exponent; i = i + 1) begin
                result = result * {base, 8'h00} / 16'd256;
                // Saturate to prevent overflow
                if (result > 16'd65280) result = 16'd65280;
            end
            power_approx = result[15:8];
        end
    endfunction

    // -------------------------------------------------------------------------
    // Square Root Approximation
    // -------------------------------------------------------------------------
    // Uses binary search algorithm to find the integer square root.
    // This is more accurate than iterative methods for integer inputs.
    //
    // Input: x - value to find square root of
    // Output: floor(sqrt(x))
    function [7:0] sqrt_approx;
        input [7:0] x;
        reg [7:0] low, high, mid, mid_sq;
        begin
            low = 0;
            high = 16;  // sqrt(255) is less than 16
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

    // =========================================================================
    // Main ALU Operation (Clocked Process)
    // =========================================================================
    // This always block implements the ALU's operation logic. It is
    // triggered on every rising clock edge or reset signal.
    //
    // The ALU operates in two modes:
    // 1. Single-cycle operations: Complete in one clock cycle
    // 2. Multi-cycle operations: Require multiple cycles (MUL, DIV, SQRT)
    
    always @(posedge clk or posedge reset) begin
        // Reset condition: clear all registers and flags
        if (reset) begin
            result <= 8'h00;
            flags <= 8'h00;
            done <= 1'b1;           // Ready for new operation
            op_in_progress <= 1'b0;  // Not in middle of operation
            
            // Clear all multi-cycle operation registers
            mul_reg <= 16'h0000;
            mul_acc <= 8'h00;
            mul_counter <= 4'h0;
            div_quotient <= 8'h00;
            div_remainder <= 8'h00;
            div_counter <= 8'h00;
            sqrt_result <= 8'h00;
            sqrt_counter <= 8'h00;
            
        // Normal operation mode
        end else begin
            // If currently executing a multi-cycle operation
            if (op_in_progress) begin
                
                // ----------------------------------------
                // Multiplication State Machine
                // ----------------------------------------
                // Performs multiplication using the shift-and-add method.
                // Each iteration processes one bit of the multiplier.
                if (operation_r == OP_MUL) begin
                    if (mul_counter < 4'd8) begin
                        // If current bit of multiplier is set, add multiplicand
                        if (b_reg[mul_counter]) begin
                            mul_acc <= mul_acc + a_reg;
                        end
                        mul_counter <= mul_counter + 1;
                    end else begin
                        // Multiplication complete after 8 iterations
                        result <= mul_acc;
                        flags[`FLAG_ZERO] <= (mul_acc == 8'h00);
                        flags[`FLAG_SIGN] <= mul_acc[7];
                        done <= 1'b1;
                        op_in_progress <= 1'b0;
                    end
                end
                
                // ----------------------------------------
                // Division State Machine
                // ----------------------------------------
                // Performs division using the restoring division algorithm.
                // Each iteration tests one bit of the quotient.
                else if (operation_r == OP_DIV) begin
                    if (div_counter < 4'd8) begin
                        // Shift remainder left and bring down next bit
                        div_remainder <= {div_remainder[6:0], div_quotient[7]};
                        div_quotient <= div_quotient << 1;
                        div_quotient[0] <= 0;
                        
                        // If remainder >= divisor, subtract and set quotient bit
                        if (div_remainder >= b_reg) begin
                            div_remainder <= div_remainder - b_reg;
                            div_quotient[0] <= 1;
                        end
                        div_counter <= div_counter + 1;
                    end else begin
                        // Division complete after 8 iterations
                        result <= div_quotient;
                        flags[`FLAG_ZERO] <= (div_quotient == 8'h00);
                        flags[`FLAG_SIGN] <= div_quotient[7];
                        done <= 1'b1;
                        op_in_progress <= 1'b0;
                    end
                end
                
                // ----------------------------------------
                // Square Root State Machine
                // ----------------------------------------
                // Uses binary search approximation for square root.
                else if (operation_r == OP_SQRT) begin
                    sqrt_result <= sqrt_approx(a_reg);
                    result <= sqrt_result;
                    flags[`FLAG_ZERO] <= (sqrt_result == 8'h00);
                    flags[`FLAG_SIGN] <= sqrt_result[7];
                    done <= 1'b1;
                    op_in_progress <= 1'b0;
                end
            end
            
            // ----------------------------------------
            // Single-Cycle Operations
            // ----------------------------------------
            // These operations complete in a single clock cycle.
            // The operation code comes from the control unit.
            else begin
                case (operation)
                    
                    // ----------------------------------------
                    // Addition Operation
                    // ----------------------------------------
                    // Adds operand B to accumulator A.
                    // Sets Carry flag if result exceeds 8 bits (overflow from bit 7).
                    // Sets Overflow flag for signed arithmetic overflow.
                    OP_ADD: begin
                        {flags[`FLAG_CARRY], result} = {1'b0, a} + {1'b0, b};
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        // Overflow detection for signed addition
                        flags[`FLAG_OVERFLOW] <= (a[7] & b[7] & ~result[7]) | 
                                                  (~a[7] & ~b[7] & result[7]);
                        done <= 1'b1;
                    end

                    // ----------------------------------------
                    // Subtraction Operation
                    // ----------------------------------------
                    // Subtracts operand B from accumulator A (A - B).
                    // Clears Carry flag if borrow is needed.
                    // Sets Overflow flag for signed arithmetic underflow.
                    OP_SUB: begin
                        {flags[`FLAG_CARRY], result} = {1'b0, a} - {1'b0, b};
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        flags[`FLAG_OVERFLOW] <= (a[7] & ~b[7] & ~result[7]) | 
                                                  (~a[7] & b[7] & result[7]);
                        done <= 1'b1;
                    end

                    // ----------------------------------------
                    // Multiplication Setup
                    // ----------------------------------------
                    // Initializes registers for multi-cycle multiplication.
                    // Multiplication is performed over 8 clock cycles
                    // using the shift-and-add algorithm.
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

                    // ----------------------------------------
                    // Division Setup
                    // ----------------------------------------
                    // Initializes registers for multi-cycle division.
                    // Division is performed over 8 clock cycles
                    // using the restoring division algorithm.
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

                    // ----------------------------------------
                    // Bitwise AND Operation
                    // ----------------------------------------
                    // Performs bitwise AND between A and B.
                    // Result bit is 1 only if both input bits are 1.
                    OP_AND: begin
                        result <= a & b;
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    // ----------------------------------------
                    // Bitwise OR Operation
                    // ----------------------------------------
                    // Performs bitwise OR between A and B.
                    // Result bit is 1 if either input bit is 1.
                    OP_OR: begin
                        result <= a | b;
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    // ----------------------------------------
                    // Bitwise XOR Operation
                    // ----------------------------------------
                    // Performs bitwise XOR (exclusive OR) between A and B.
                    // Result bit is 1 only if input bits are different.
                    OP_XOR: begin
                        result <= a ^ b;
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    // ----------------------------------------
                    // Bitwise NOT Operation
                    // ----------------------------------------
                    // Inverts all bits of accumulator A.
                    OP_NOT: begin
                        result <= ~a;
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    // ----------------------------------------
                    // Shift Left Operation
                    // ----------------------------------------
                    // Moves all bits one position to the left.
                    // Bit 7 becomes the Carry flag, Bit 0 becomes 0.
                    OP_SHL: begin
                        {flags[`FLAG_CARRY], result} = {a, 1'b0};
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    // ----------------------------------------
                    // Shift Right Operation
                    // ----------------------------------------
                    // Moves all bits one position to the right.
                    // Bit 0 becomes the Carry flag, Bit 7 becomes 0.
                    OP_SHR: begin
                        {flags[`FLAG_CARRY], result} = {1'b0, a};
                        result <= {1'b0, a[7:1]};
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    // ----------------------------------------
                    // Rotate Left Operation
                    // ----------------------------------------
                    // Moves all bits one position to the left.
                    // Bit 7 becomes the Carry flag, Carry becomes Bit 0.
                    OP_ROL: begin
                        {flags[`FLAG_CARRY], result} = {a[0], a};
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    // ----------------------------------------
                    // Rotate Right Operation
                    // ----------------------------------------
                    // Moves all bits one position to the right.
                    // Bit 0 becomes the Carry flag, Carry becomes Bit 7.
                    OP_ROR: begin
                        {flags[`FLAG_CARRY], result} = {a[0], a};
                        result <= {C, a[7:1]};
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        done <= 1'b1;
                    end

                    // ----------------------------------------
                    // Increment Operation
                    // ----------------------------------------
                    // Adds 1 to the accumulator.
                    // Sets Overflow flag when crossing from 127 to -128.
                    OP_INC: begin
                        result <= a + 1;
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        flags[`FLAG_OVERFLOW] <= (a == 8'h7F);
                        done <= 1'b1;
                    end

                    // ----------------------------------------
                    // Decrement Operation
                    // ----------------------------------------
                    // Subtracts 1 from the accumulator.
                    // Sets Overflow flag when crossing from -128 to 127.
                    OP_DEC: begin
                        result <= a - 1;
                        flags[`FLAG_ZERO] <= (result == 8'h00);
                        flags[`FLAG_SIGN] <= result[7];
                        flags[`FLAG_OVERFLOW] <= (a == 8'h80);
                        done <= 1'b1;
                    end

                    // ----------------------------------------
                    // Compare Operation
                    // ----------------------------------------
                    // Performs subtraction but doesn't store result.
                    // Only updates flags to indicate comparison result.
                    // Useful for conditional branches.
                    OP_CMP: begin
                        {flags[`FLAG_CARRY], result} = {1'b0, a} - {1'b0, b};
                        flags[`FLAG_ZERO] <= (a == b);
                        flags[`FLAG_SIGN] <= result[7];
                        flags[`FLAG_OVERFLOW] <= (a[7] & ~b[7] & ~result[7]) | 
                                                  (~a[7] & b[7] & result[7]);
                        done <= 1'b1;
                    end

                    // ----------------------------------------
                    // Square Root Setup
                    // ----------------------------------------
                    // Initializes registers for square root calculation.
                    OP_SQRT: begin
                        operation_r <= operation;
                        a_reg <= a;
                        op_in_progress <= 1'b1;
                        done <= 1'b0;
                    end

                    // Default case: no operation
                    default: begin
                        done <= 1'b1;
                    end
                endcase
            end
        end
    end

endmodule
