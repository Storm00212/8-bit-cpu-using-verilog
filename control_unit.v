// ============================================================================
// Control Unit
// ============================================================================
// 
// The Control Unit is the "brain" of the CPU. It coordinates all other
// components by decoding instructions and generating control signals.
// 
// Primary Functions:
// 1. Instruction Fetch - Read opcodes from memory
// 2. Instruction Decode - Determine what operation to perform
// 3. Execute - Generate control signals for the operation
// 4. Control Flow - Handle branches, jumps, and subroutine calls
// 
// Architecture:
// - Finite State Machine (FSM) based design
// - Separate fetch/decode/execute stages
// - Microcode-like control signal generation
// ============================================================================

`include "instructions.vh"

module control_unit (
    // Clock and reset signals
    input wire clk,             // System clock
    input wire reset,           // Asynchronous reset
    
    // Inputs from other CPU components
    input wire [7:0] opcode,    // Current opcode from instruction register
    input wire [7:0] flags_in,  // Current flags from flags register
    input wire alu_done,        // ALU operation completion signal
    input wire [7:0] data_bus,  // Data bus input (from memory)
    input wire [15:0] pc_current, // Current program counter value
    
    // Outputs to other CPU components
    output reg [7:0] opcode_out,   // Opcode output (to ALU/memory)
    output reg [3:0] alu_operation, // ALU operation code
    output reg acc_write,          // Write enable for accumulator
    output reg x_write,            // Write enable for X register
    output reg y_write,            // Write enable for Y register
    output reg pc_write,           // Write enable for PC
    output reg pc_inc,             // Increment PC
    output reg pc_load,            // Load PC from data bus
    output reg [15:0] pc_direct,   // Direct PC value for jumps
    output reg sp_write,           // Write enable for stack pointer
    output reg ir_write,           // Write enable for instruction register
    output reg flags_write,         // Write enable for flags register
    output reg mem_read,           // Memory read enable
    output reg mem_write,          // Memory write enable
    output reg [15:0] mem_addr,    // Memory address
    output reg done,               // Instruction complete signal
    
    // Debug outputs
    output reg [2:0] fetch_state,  // Current fetch state
    output reg [7:0] state_debug   // Debug state information
);

    // =========================================================================
    // FSM State Definitions
    // =========================================================================
    // The control unit uses a finite state machine to process instructions.
    // Each state represents a step in the instruction execution pipeline.
    
    localparam STATE_IDLE       = 4'h0;  // Idle state, waiting for next instruction
    localparam STATE_FETCH      = 4'h1;  // Fetch instruction from memory
    localparam STATE_DECODE     = 4'h2;  // Decode the instruction opcode
    localparam STATE_EXECUTE    = 4'h3;  // Execute the instruction
    localparam STATE_MEM_READ   = 4'h4;  // Read data from memory
    localparam STATE_MEM_WRITE  = 4'h5;  // Write data to memory
    localparam STATE_ALU_OP     = 4'h6;  // Perform ALU operation
    localparam STATE_BRANCH     = 4'h7;  // Handle branch operation
    localparam STATE_JUMP       = 4'h8;  // Handle jump operation

    // =========================================================================
    // ALU Operation Codes
    // =========================================================================
    // These localparam values map to the ALU operation codes defined in alu.v.
    
    localparam OP_ADD   = 4'h0;   // Addition
    localparam OP_SUB   = 4'h1;   // Subtraction
    localparam OP_MUL   = 4'h2;   // Multiplication
    localparam OP_DIV   = 4'h3;   // Division
    localparam OP_AND   = 4'h4;   // Bitwise AND
    localparam OP_OR    = 4'h5;   // Bitwise OR
    localparam OP_XOR   = 4'h6;   // Bitwise XOR
    localparam OP_NOT   = 4'h7;   // Bitwise NOT
    localparam OP_SHL   = 4'h8;   // Shift Left
    localparam OP_SHR   = 4'h9;   // Shift Right
    localparam OP_ROL   = 4'hA;   // Rotate Left
    localparam OP_ROR   = 4'hB;   // Rotate Right
    localparam OP_INC   = 4'hC;   // Increment
    localparam OP_DEC   = 4'hD;   // Decrement
    localparam OP_CMP   = 4'hE;   // Compare
    localparam OP_SQRT  = 4'hF;   // Square Root

    // =========================================================================
    // Flag Bit Extraction
    // =========================================================================
    // Extract individual flag bits for branch condition checking.
    
    wire C, Z, N, V;  // Carry, Zero, Negative, Overflow flags
    
    assign C = flags_in[`FLAG_CARRY];
    assign Z = flags_in[`FLAG_ZERO];
    assign N = flags_in[`FLAG_SIGN];
    assign V = flags_in[`FLAG_OVERFLOW];

    // =========================================================================
    // Internal Registers
    // =========================================================================
    // These registers store state information during instruction processing.
    
    reg [3:0] state;        // Current FSM state
    reg [7:0] opcode_reg;  // Registered opcode
    reg [7:0] operand1, operand2;  // Operand storage
    reg [15:0] jump_addr;  // Jump target address

    // =========================================================================
    // Main FSM Process
    // =========================================================================
    // This always block implements the finite state machine that controls
    // instruction execution. It is triggered on clock edges and reset.
    
    always @(posedge clk or posedge reset) begin
        // Reset condition: initialize all control signals
        if (reset) begin
            state <= STATE_IDLE;
            opcode_reg <= 8'h00;
            
            // Clear all control signals
            acc_write <= 1'b0;
            x_write <= 1'b0;
            y_write <= 1'b0;
            pc_write <= 1'b0;
            pc_inc <= 1'b0;
            pc_load <= 1'b0;
            sp_write <= 1'b0;
            ir_write <= 1'b0;
            flags_write <= 1'b0;
            mem_read <= 1'b0;
            mem_write <= 1'b0;
            alu_operation <= 4'h0;
            opcode_out <= 8'h00;
            done <= 1'b1;
            fetch_state <= 3'h0;
            state_debug <= 8'h00;
            
        // Normal operation
        end else begin
            case (state)
                
                // ----------------------------------------
                // IDLE State
                // ----------------------------------------
                // The CPU is idle and ready to fetch the next instruction.
                // Transition to FETCH state to begin instruction cycle.
                STATE_IDLE: begin
                    state <= STATE_FETCH;
                    
                    // Clear control signals
                    pc_inc <= 1'b0;
                    pc_write <= 1'b0;
                    acc_write <= 1'b0;
                    x_write <= 1'b0;
                    y_write <= 1'b0;
                    mem_read <= 1'b0;
                    mem_write <= 1'b0;
                    done <= 1'b0;
                    state_debug <= 8'h01;
                end

                // ----------------------------------------
                // FETCH State
                // ----------------------------------------
                // Read the opcode from memory at the current PC address.
                // This is the first step of every instruction.
                STATE_FETCH: begin
                    // Set up memory read
                    mem_addr <= pc_current;
                    mem_read <= 1'b1;
                    ir_write <= 1'b1;  // Load opcode into IR
                    
                    // Move to decode state
                    state <= STATE_DECODE;
                    fetch_state <= 3'h1;
                    state_debug <= 8'h02;
                end

                // ----------------------------------------
                // DECODE State
                // ----------------------------------------
                // The opcode is now on the data bus from memory.
                // Register it and move to execution.
                STATE_DECODE: begin
                    // Complete the read operation
                    mem_read <= 1'b0;
                    ir_write <= 1'b0;
                    
                    // Register the opcode for execution
                    opcode_reg <= data_bus;
                    opcode_out <= data_bus;
                    
                    // Move to execute state
                    state <= STATE_EXECUTE;
                    state_debug <= 8'h03;
                end

                // ----------------------------------------
                // EXECUTE State
                // ----------------------------------------
                // Decode and execute the instruction based on opcode.
                // This is the main dispatch logic.
                STATE_EXECUTE: begin
                    case (data_bus)
                        
                        // ----------------------------------------
                        // No Operation (NOP)
                        // ----------------------------------------
                        // Does nothing, just advances to next instruction.
                        `OPCODE_NOP: begin
                            done <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_IDLE;
                        end

                        // ----------------------------------------
                        // Load Accumulator Immediate
                        // ----------------------------------------
                        // LDA #imm: Load accumulator with following byte.
                        // Requires reading the immediate value from memory.
                        `OPCODE_LDA_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                        end

                        // ----------------------------------------
                        // Load Accumulator Direct
                        // ----------------------------------------
                        // LDA dir: Load accumulator from specified address.
                        // First read the address, then read from that address.
                        `OPCODE_LDA_DIR: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                        end

                        // ----------------------------------------
                        // Store Accumulator Direct
                        // ----------------------------------------
                        // STA dir: Store accumulator to specified address.
                        `OPCODE_STA_DIR: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                        end

                        // ----------------------------------------
                        // Load X Register Immediate
                        // ----------------------------------------
                        `OPCODE_LDX_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                        end

                        // ----------------------------------------
                        // Load Y Register Immediate
                        // ----------------------------------------
                        `OPCODE_LDY_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                        end

                        // ----------------------------------------
                        // Add Immediate
                        // ----------------------------------------
                        // ADD #imm: Add following byte to accumulator.
                        `OPCODE_ADD_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                            alu_operation <= OP_ADD;
                        end

                        // ----------------------------------------
                        // Subtract Immediate
                        // ----------------------------------------
                        // SUB #imm: Subtract following byte from accumulator.
                        `OPCODE_SUB_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                            alu_operation <= OP_SUB;
                        end

                        // ----------------------------------------
                        // Multiply
                        // ----------------------------------------
                        // MUL: Multiply accumulator by X register.
                        // Multi-cycle operation, uses ALU state machine.
                        `OPCODE_MUL: begin
                            alu_operation <= OP_MUL;
                            state <= STATE_ALU_OP;
                        end

                        // ----------------------------------------
                        // Divide
                        // ----------------------------------------
                        // DIV: Divide accumulator by X register.
                        // Multi-cycle operation, uses ALU state machine.
                        `OPCODE_DIV: begin
                            alu_operation <= OP_DIV;
                            state <= STATE_ALU_OP;
                        end

                        // ----------------------------------------
                        // Increment
                        // ----------------------------------------
                        // INC: Add 1 to accumulator.
                        `OPCODE_INC: begin
                            alu_operation <= OP_INC;
                            state <= STATE_ALU_OP;
                        end

                        // ----------------------------------------
                        // Decrement
                        // ----------------------------------------
                        // DEC: Subtract 1 from accumulator.
                        `OPCODE_DEC: begin
                            alu_operation <= OP_DEC;
                            state <= STATE_ALU_OP;
                        end

                        // ----------------------------------------
                        // AND Immediate
                        // ----------------------------------------
                        `OPCODE_AND_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                            alu_operation <= OP_AND;
                        end

                        // ----------------------------------------
                        // OR Immediate
                        // ----------------------------------------
                        `OPCODE_OR_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                            alu_operation <= OP_OR;
                        end

                        // ----------------------------------------
                        // XOR Immediate
                        // ----------------------------------------
                        `OPCODE_XOR_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                            alu_operation <= OP_XOR;
                        end

                        // ----------------------------------------
                        // NOT Accumulator
                        // ----------------------------------------
                        `OPCODE_NOT: begin
                            alu_operation <= OP_NOT;
                            state <= STATE_ALU_OP;
                        end

                        // ----------------------------------------
                        // Shift Left
                        // ----------------------------------------
                        `OPCODE_SHL: begin
                            alu_operation <= OP_SHL;
                            state <= STATE_ALU_OP;
                        end

                        // ----------------------------------------
                        // Shift Right
                        // ----------------------------------------
                        `OPCODE_SHR: begin
                            alu_operation <= OP_SHR;
                            state <= STATE_ALU_OP;
                        end

                        // ----------------------------------------
                        // Rotate Left
                        // ----------------------------------------
                        `OPCODE_ROL: begin
                            alu_operation <= OP_ROL;
                            state <= STATE_ALU_OP;
                        end

                        // ----------------------------------------
                        // Rotate Right
                        // ----------------------------------------
                        `OPCODE_ROR: begin
                            alu_operation <= OP_ROR;
                            state <= STATE_ALU_OP;
                        end

                        // ----------------------------------------
                        // Compare Immediate
                        // ----------------------------------------
                        `OPCODE_CMP_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                            alu_operation <= OP_CMP;
                        end

                        // ----------------------------------------
                        // Branch if Equal (BEQ)
                        // ----------------------------------------
                        // Branch to offset if Zero flag is set.
                        `OPCODE_BEQ: begin
                            if (Z) begin
                                mem_addr <= pc_current + 16'h0001;
                                mem_read <= 1'b1;
                                pc_inc <= 1'b1;
                                state <= STATE_BRANCH;
                            end else begin
                                pc_inc <= 1'b1;
                                done <= 1'b1;
                                state <= STATE_IDLE;
                            end
                        end

                        // ----------------------------------------
                        // Branch if Not Equal (BNE)
                        // ----------------------------------------
                        // Branch to offset if Zero flag is clear.
                        `OPCODE_BNE: begin
                            if (~Z) begin
                                mem_addr <= pc_current + 16'h0001;
                                mem_read <= 1'b1;
                                pc_inc <= 1'b1;
                                state <= STATE_BRANCH;
                            end else begin
                                pc_inc <= 1'b1;
                                done <= 1'b1;
                                state <= STATE_IDLE;
                            end
                        end

                        // ----------------------------------------
                        // Branch if Minus (BMI)
                        // ----------------------------------------
                        // Branch if Negative flag is set.
                        `OPCODE_BMI: begin
                            if (N) begin
                                mem_addr <= pc_current + 16'h0001;
                                mem_read <= 1'b1;
                                pc_inc <= 1'b1;
                                state <= STATE_BRANCH;
                            end else begin
                                pc_inc <= 1'b1;
                                done <= 1'b1;
                                state <= STATE_IDLE;
                            end
                        end

                        // ----------------------------------------
                        // Branch if Plus (BPL)
                        // ----------------------------------------
                        // Branch if Negative flag is clear.
                        `OPCODE_BPL: begin
                            if (~N) begin
                                mem_addr <= pc_current + 16'h0001;
                                mem_read <= 1'b1;
                                pc_inc <= 1'b1;
                                state <= STATE_BRANCH;
                            end else begin
                                pc_inc <= 1'b1;
                                done <= 1'b1;
                                state <= STATE_IDLE;
                            end
                        end

                        // ----------------------------------------
                        // Branch if Carry Set (BCS)
                        // ----------------------------------------
                        `OPCODE_BCS: begin
                            if (C) begin
                                mem_addr <= pc_current + 16'h0001;
                                mem_read <= 1'b1;
                                pc_inc <= 1'b1;
                                state <= STATE_BRANCH;
                            end else begin
                                pc_inc <= 1'b1;
                                done <= 1'b1;
                                state <= STATE_IDLE;
                            end
                        end

                        // ----------------------------------------
                        // Branch if Carry Clear (BCC)
                        // ----------------------------------------
                        `OPCODE_BCC: begin
                            if (~C) begin
                                mem_addr <= pc_current + 16'h0001;
                                mem_read <= 1'b1;
                                pc_inc <= 1'b1;
                                state <= STATE_BRANCH;
                            end else begin
                                pc_inc <= 1'b1;
                                done <= 1'b1;
                                state <= STATE_IDLE;
                            end
                        end

                        // ----------------------------------------
                        // Branch Always (BRA)
                        // ----------------------------------------
                        // Unconditional branch to offset.
                        `OPCODE_BRA: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_BRANCH;
                        end

                        // ----------------------------------------
                        // Jump Direct (JMP)
                        // ----------------------------------------
                        // Unconditional jump to absolute address.
                        `OPCODE_JMP_DIR: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_JUMP;
                        end

                        // ----------------------------------------
                        // Absolute Value (ABS)
                        // ----------------------------------------
                        `OPCODE_ABS: begin
                            alu_operation <= OP_CMP;
                            state <= STATE_ALU_OP;
                        end

                        // ----------------------------------------
                        // Negate (NEG)
                        // ----------------------------------------
                        `OPCODE_NEG: begin
                            alu_operation <= OP_NOT;
                            state <= STATE_ALU_OP;
                        end

                        // ----------------------------------------
                        // Square Root (SQRT)
                        // ----------------------------------------
                        `OPCODE_SQRT: begin
                            alu_operation <= OP_SQRT;
                            state <= STATE_ALU_OP;
                        end

                        // ----------------------------------------
                        // Unknown Opcode
                        // ----------------------------------------
                        // Treat as NOP for robustness.
                        default: begin
                            done <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_IDLE;
                        end
                    endcase
                end

                // ----------------------------------------
                // Memory Read State
                // ----------------------------------------
                // Complete memory read operations and route data.
                STATE_MEM_READ: begin
                    mem_read <= 1'b0;
                    operand1 <= data_bus;

                    case (opcode_reg)
                        `OPCODE_LDA_IMM: begin
                            acc_write <= 1'b1;
                            done <= 1'b1;
                            state <= STATE_IDLE;
                        end

                        `OPCODE_LDA_DIR: begin
                            mem_addr <= {8'h00, data_bus};
                            mem_read <= 1'b1;
                            state <= STATE_MEM_READ;
                        end

                        `OPCODE_STA_DIR: begin
                            mem_addr <= {8'h00, data_bus};
                            mem_write <= 1'b1;
                            state <= STATE_MEM_WRITE;
                        end

                        `OPCODE_LDX_IMM: begin
                            x_write <= 1'b1;
                            done <= 1'b1;
                            state <= STATE_IDLE;
                        end

                        `OPCODE_LDY_IMM: begin
                            y_write <= 1'b1;
                            done <= 1'b1;
                            state <= STATE_IDLE;
                        end

                        `OPCODE_ADD_IMM, `OPCODE_SUB_IMM,
                        `OPCODE_AND_IMM, `OPCODE_OR_IMM,
                        `OPCODE_XOR_IMM, `OPCODE_CMP_IMM: begin
                            state <= STATE_ALU_OP;
                        end

                        default: begin
                            done <= 1'b1;
                            state <= STATE_IDLE;
                        end
                    endcase
                end

                // ----------------------------------------
                // Memory Write State
                // ----------------------------------------
                // Complete memory write operations.
                STATE_MEM_WRITE: begin
                    mem_write <= 1'b0;
                    done <= 1'b1;
                    state <= STATE_IDLE;
                end

                // ----------------------------------------
                // ALU Operation State
                // ----------------------------------------
                // Wait for ALU to complete multi-cycle operations.
                STATE_ALU_OP: begin
                    if (alu_done) begin
                        acc_write <= 1'b1;
                        pc_inc <= 1'b1;
                        done <= 1'b1;
                        state <= STATE_IDLE;
                        acc_write <= 1'b0;
                    end
                end

                // ----------------------------------------
                // Branch State
                // ----------------------------------------
                // Handle branch offset calculation and PC update.
                STATE_BRANCH: begin
                    mem_read <= 1'b0;
                    pc_direct <= pc_current;
                    pc_load <= 1'b1;
                    pc_write <= 1'b1;
                    done <= 1'b1;
                    state <= STATE_IDLE;
                    pc_load <= 1'b0;
                    pc_write <= 1'b0;
                end

                // ----------------------------------------
                // Jump State
                // ----------------------------------------
                // Handle absolute jump address loading.
                STATE_JUMP: begin
                    mem_read <= 1'b0;
                    pc_direct <= pc_current;
                    pc_load <= 1'b1;
                    pc_write <= 1'b1;
                    done <= 1'b1;
                    state <= STATE_IDLE;
                    pc_load <= 1'b0;
                    pc_write <= 1'b0;
                end

                // ----------------------------------------
                // Default State
                // ----------------------------------------
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
