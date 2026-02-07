// ============================================================================
// Register File Module
// ============================================================================
// 
// The Register File is a crucial component of the CPU that stores all
// the internal registers used during program execution. It provides
// read/write access to these registers based on control signals from
// the Control Unit.
// 
// Registers Implemented:
// - ACC (Accumulator): Primary register for arithmetic and logic operations
// - X Register: Index register for addressing and loops
// - Y Register: Secondary index register
// - PC (Program Counter): Points to the next instruction to execute
// - SP (Stack Pointer): Points to the current top of the stack
// - IR (Instruction Register): Holds the current instruction opcode
// - Flags: Status register indicating condition codes
// 
// Architecture:
// - All registers are 8-bit except PC which is 16-bit
// - Register writes are synchronous (clocked)
// - Register reads are combinational (asynchronous)
// - Bidirectional data bus for register transfers
// ============================================================================

`include "instructions.vh"

module register_file (
    // Clock and reset signals
    input wire clk,              // System clock - all operations are synchronous
    input wire reset,            // Asynchronous reset - clears all registers
    
    // Data bus interface
    input wire [7:0] data_in,    // Data input from the data bus
    output reg [7:0] acc_out,    // Accumulator value to data bus/ALU
    output reg [7:0] x_out,      // X register value to data bus/ALU
    output reg [7:0] y_out,      // Y register value to data bus/ALU
    output reg [7:0] sp_out,     // Stack pointer value
    output reg [7:0] ir_out,     // Instruction register value
    output reg [7:0] flags_out,  // Flags register value
    
    // Write enable signals (from Control Unit)
    input wire acc_write,        // Enable write to accumulator
    input wire x_write,          // Enable write to X register
    input wire y_write,          // Enable write to Y register
    input wire sp_write,         // Enable write to stack pointer
    input wire ir_write,         // Enable write to instruction register
    input wire flags_write,      // Enable write to flags register
    
    // Program Counter control signals
    input wire pc_write,         // Enable write to PC (for jumps)
    input wire pc_inc,           // Increment PC (for sequential execution)
    input wire pc_load,          // Load PC from data bus (for relative branches)
    input wire [15:0] pc_direct, // Direct PC value (high byte for jumps)
    
    // Address bus output
    output reg [15:0] addr_bus   // Current address on the address bus
);

    // =========================================================================
    // Internal Register Storage
    // =========================================================================
    // These are the actual storage elements for the CPU registers.
    // They are updated on the rising edge of the clock when their
    // respective write enable signals are asserted.
    
    reg [7:0] acc;       // Accumulator - primary arithmetic register
    reg [7:0] x_reg;    // X index register
    reg [7:0] y_reg;    // Y index register
    reg [15:0] pc;       // Program Counter - 16-bit for 64KB addressing
    reg [7:0] sp;        // Stack Pointer - 8-bit (256 byte stack)
    reg [7:0] ir;        // Instruction Register - holds current opcode
    reg [7:0] flags;     // Status Flags register
    
    // =========================================================================
    // Flag Bit Extraction
    // =========================================================================
    // Extract individual flag bits for easier access in operations.
    // These wires provide direct access to specific flag bits.
    
    wire C, Z, N, V;    // Carry, Zero, Negative, Overflow flags
    
    assign C = flags[`FLAG_CARRY];
    assign Z = flags[`FLAG_ZERO];
    assign N = flags[`FLAG_SIGN];
    assign V = flags[`FLAG_OVERFLOW];

    // =========================================================================
    // Register File Operation
    // =========================================================================
    // This always block handles all register writes and updates.
    // It is triggered on the rising edge of the clock or reset.
    //
    // Register Write Priority:
    // - Multiple registers can be written in the same cycle
    // - Each register has its own independent write enable
    // - Reset has highest priority and clears all registers
    
    always @(posedge clk or posedge reset) begin
        // Reset condition: clear all registers to known state
        if (reset) begin
            // Clear all 8-bit registers
            acc <= 8'h00;
            x_reg <= 8'h00;
            y_reg <= 8'h00;
            sp <= 8'h00;
            ir <= 8'h00;
            flags <= 8'h00;
            
            // Clear 16-bit registers
            pc <= 16'h0000;
            
            // Initialize output registers
            acc_out <= 8'h00;
            x_out <= 8'h00;
            y_out <= 8'h00;
            sp_out <= 8'hFF;  // Stack starts at top of stack page
            ir_out <= 8'h00;
            flags_out <= 8'h00;
            addr_bus <= 16'h0000;
            
        end else begin
            // ------------------------------------------------
            // Register Write Operations
            // ------------------------------------------------
            // Each register is written when its write enable is asserted.
            // The data comes from the data_in input.
            
            // Accumulator write
            if (acc_write) acc <= data_in;
            
            // X register write
            if (x_write) x_reg <= data_in;
            
            // Y register write
            if (y_write) y_reg <= data_in;
            
            // Stack pointer write
            if (sp_write) sp <= data_in;
            
            // ------------------------------------------------
            // Program Counter Operations
            // ------------------------------------------------
            // The PC can be updated in three ways:
            // 1. pc_write: Direct write (for absolute jumps)
            // 2. pc_inc: Increment by 1 (for sequential execution)
            // 3. pc_load: Load from data bus (for relative branches)
            
            if (pc_write) begin
                // Direct write to PC (used by JMP instruction)
                // The high byte comes from pc_direct, low byte from data_in
                if (pc_direct[15:8] != 8'h00) begin
                    pc <= {pc_direct[15:8], data_in};
                end else begin
                    // Zero page jump - use direct address
                    pc <= {8'h00, data_in};
                end
            end else if (pc_inc) begin
                // Increment PC by 1 (normal instruction sequencing)
                pc <= pc + 16'h0001;
            end else if (pc_load) begin
                // Load PC from data bus (used by relative branches)
                // Similar to direct write
                if (pc_direct[15:8] != 8'h00) begin
                    pc <= {pc_direct[15:8], data_in};
                end else begin
                    pc <= {8'h00, data_in};
                end
            end
            
            // ------------------------------------------------
            // Instruction Register Write
            // ------------------------------------------------
            // The IR is loaded with the current opcode during
            // the instruction fetch cycle.
            if (ir_write) ir <= data_in;
            
            // ------------------------------------------------
            // Flags Register Write
            // ------------------------------------------------
            // The flags register can be written directly (for PLP, etc.)
            // or updated by ALU operations.
            if (flags_write) flags <= data_in;
            
            // ------------------------------------------------
            // Output Register Updates
            // ------------------------------------------------
            // Update the output registers that drive external modules.
            // These are the values seen by the ALU, control unit, etc.
            acc_out <= acc;
            x_out <= x_reg;
            y_out <= y_reg;
            pc_out <= pc;
            sp_out <= sp;
            ir_out <= ir;
            flags_out <= flags;
            
            // ------------------------------------------------
            // Address Bus Generation
            // ------------------------------------------------
            // The address bus is driven by the PC during instruction fetch.
            // This is the memory address for reading the next instruction.
            addr_bus <= pc;
        end
    end

    // =========================================================================
    // Stack Operations (Tasks)
    // =========================================================================
    // These tasks provide high-level stack operations. They are used
    // by the Control Unit to implement PUSH and PULL instructions.
    //
    // Stack Behavior:
    // - Stack grows downward from 0x01FF to 0x0100
    // - SP points to the next empty location (pre-decrement for push)
    // - SP is incremented after reading (post-increment for pull)
    
    // Push a value onto the stack
    // Decrements SP, then writes value to the new stack location
    task push;
        input [7:0] value;       // Value to push onto stack
        
        begin
            sp <= sp - 1;         // Decrement stack pointer
            // Memory write would happen in RAM module
        end
    endtask
    
    // Pull a value from the stack
    // Reads value from current stack location, then increments SP
    task pull;
        output [7:0] value;      // Value pulled from stack
        
        begin
            value = 8'h00;        // Value would be read from RAM
            sp <= sp + 1;         // Increment stack pointer
        end
    endtask

endmodule
