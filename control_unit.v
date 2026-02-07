// ============================================================
// Control Unit
// Decodes instructions and generates control signals
// ============================================================

`include "instructions.vh"

module control_unit (
    input wire        clk,             // Clock
    input wire        reset,           // Reset
    input wire [7:0]  opcode,          // Current opcode
    input wire [7:0] flags_in,        // Flags from register file
    input wire        alu_done,        // ALU operation complete
    input wire [7:0]  data_bus,        // Data bus input
    input wire [15:0] pc_current,      // Current PC value
    
    output reg [7:0]  opcode_out,      // Opcode to ALU/memory
    output reg [3:0]  alu_operation,   // ALU operation code
    output reg        acc_write,       // Write to accumulator
    output reg        x_write,         // Write to X register
    output reg        y_write,         // Write to Y register
    output reg        pc_write,        // Write to PC
    output reg        pc_inc,          // Increment PC
    output reg        pc_load,         // Load PC from data bus
    output reg [15:0] pc_direct,       // Direct PC value
    output reg        sp_write,        // Write to stack pointer
    output reg        ir_write,        // Write to instruction register
    output reg        flags_write,     // Write to flags register
    output reg        mem_read,        // Memory read
    output reg        mem_write,       // Memory write
    output reg [15:0] mem_addr,       // Memory address
    output reg        done,            // Instruction complete
    output reg [2:0]  fetch_state,    // Current fetch state
    output reg [7:0]  state_debug     // Debug state info
);

    // FSM states
    localparam STATE_IDLE       = 4'h0;
    localparam STATE_FETCH      = 4'h1;
    localparam STATE_DECODE     = 4'h2;
    localparam STATE_EXECUTE    = 4'h3;
    localparam STATE_MEM_READ   = 4'h4;
    localparam STATE_MEM_WRITE  = 4'h5;
    localparam STATE_ALU_OP     = 4'h6;
    localparam STATE_BRANCH     = 4'h7;
    localparam STATE_JUMP       = 4'h8;

    // ALU operations (from alu.v)
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

    // Flags
    wire C, Z, N, V;
    assign C = flags_in[`FLAG_CARRY];
    assign Z = flags_in[`FLAG_ZERO];
    assign N = flags_in[`FLAG_SIGN];
    assign V = flags_in[`FLAG_OVERFLOW];

    // Current state
    reg [3:0] state;
    reg [7:0] opcode_reg;
    reg [7:0] operand1, operand2;
    reg [15:0] jump_addr;

    // FSM state machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= STATE_IDLE;
            opcode_reg <= 8'h00;
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
        end else begin
            case (state)
                STATE_IDLE: begin
                    // Start instruction fetch
                    state <= STATE_FETCH;
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

                STATE_FETCH: begin
                    // Read opcode from memory at PC
                    mem_addr <= pc_current;
                    mem_read <= 1'b1;
                    ir_write <= 1'b1;
                    state <= STATE_DECODE;
                    fetch_state <= 3'h1;
                    state_debug <= 8'h02;
                end

                STATE_DECODE: begin
                    // Opcode is on data bus
                    mem_read <= 1'b0;
                    ir_write <= 1'b0;
                    opcode_reg <= data_bus;
                    opcode_out <= data_bus;
                    state <= STATE_EXECUTE;
                    state_debug <= 8'h03;
                end

                STATE_EXECUTE: begin
                    // Decode and execute instruction
                    case (data_bus)
                        // NOP
                        `OPCODE_NOP: begin
                            done <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_IDLE;
                        end

                        // Load/Store operations
                        `OPCODE_LDA_IMM: begin
                            // Next byte is immediate value
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                        end

                        `OPCODE_LDA_DIR: begin
                            // Next byte is memory address (low)
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                        end

                        `OPCODE_STA_DIR: begin
                            // Next byte is memory address
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                        end

                        `OPCODE_LDX_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                        end

                        `OPCODE_LDY_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                        end

                        // Arithmetic operations
                        `OPCODE_ADD_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                            alu_operation <= OP_ADD;
                        end

                        `OPCODE_SUB_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                            alu_operation <= OP_SUB;
                        end

                        `OPCODE_MUL: begin
                            // Multiply accumulator by X register
                            alu_operation <= OP_MUL;
                            state <= STATE_ALU_OP;
                        end

                        `OPCODE_DIV: begin
                            // Divide accumulator by X register
                            alu_operation <= OP_DIV;
                            state <= STATE_ALU_OP;
                        end

                        `OPCODE_INC: begin
                            alu_operation <= OP_INC;
                            state <= STATE_ALU_OP;
                        end

                        `OPCODE_DEC: begin
                            alu_operation <= OP_DEC;
                            state <= STATE_ALU_OP;
                        end

                        // Logical operations
                        `OPCODE_AND_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                            alu_operation <= OP_AND;
                        end

                        `OPCODE_OR_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                            alu_operation <= OP_OR;
                        end

                        `OPCODE_XOR_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                            alu_operation <= OP_XOR;
                        end

                        `OPCODE_NOT: begin
                            alu_operation <= OP_NOT;
                            state <= STATE_ALU_OP;
                        end

                        // Shift/Rotate operations
                        `OPCODE_SHL: begin
                            alu_operation <= OP_SHL;
                            state <= STATE_ALU_OP;
                        end

                        `OPCODE_SHR: begin
                            alu_operation <= OP_SHR;
                            state <= STATE_ALU_OP;
                        end

                        `OPCODE_ROL: begin
                            alu_operation <= OP_ROL;
                            state <= STATE_ALU_OP;
                        end

                        `OPCODE_ROR: begin
                            alu_operation <= OP_ROR;
                            state <= STATE_ALU_OP;
                        end

                        // Compare operations
                        `OPCODE_CMP_IMM: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_MEM_READ;
                            alu_operation <= OP_CMP;
                        end

                        // Branch operations
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

                        `OPCODE_BRA: begin
                            // Unconditional branch
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_BRANCH;
                        end

                        // Jump operations
                        `OPCODE_JMP_DIR: begin
                            mem_addr <= pc_current + 16'h0001;
                            mem_read <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_JUMP;
                        end

                        // Scientific operations
                        `OPCODE_ABS: begin
                            alu_operation <= OP_CMP;
                            state <= STATE_ALU_OP;
                        end

                        `OPCODE_NEG: begin
                            alu_operation <= OP_NOT;
                            state <= STATE_ALU_OP;
                        end

                        `OPCODE_SQRT: begin
                            alu_operation <= OP_SQRT;
                            state <= STATE_ALU_OP;
                        end

                        default: begin
                            // Unknown opcode - treat as NOP
                            done <= 1'b1;
                            pc_inc <= 1'b1;
                            state <= STATE_IDLE;
                        end
                    endcase
                end

                STATE_MEM_READ: begin
                    // Read operand from memory
                    mem_read <= 1'b0;
                    operand1 <= data_bus;

                    case (opcode_reg)
                        `OPCODE_LDA_IMM: begin
                            acc_write <= 1'b1;
                            done <= 1'b1;
                            state <= STATE_IDLE;
                        end

                        `OPCODE_LDA_DIR: begin
                            // Read from the address we just got
                            mem_addr <= {8'h00, data_bus};
                            mem_read <= 1'b1;
                            state <= STATE_MEM_READ;
                        end

                        `OPCODE_STA_DIR: begin
                            // Write accumulator to memory address
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
                            // ALU operation with immediate value
                            state <= STATE_ALU_OP;
                        end

                        default: begin
                            done <= 1'b1;
                            state <= STATE_IDLE;
                        end
                    endcase
                end

                STATE_MEM_WRITE: begin
                    mem_write <= 1'b0;
                    done <= 1'b1;
                    state <= STATE_IDLE;
                end

                STATE_ALU_OP: begin
                    // Wait for ALU to complete
                    if (alu_done) begin
                        acc_write <= 1'b1;
                        pc_inc <= 1'b1;
                        done <= 1'b1;
                        state <= STATE_IDLE;
                        acc_write <= 1'b0;
                    end
                end

                STATE_BRANCH: begin
                    // Read offset and calculate new PC
                    mem_read <= 1'b0;
                    pc_direct <= pc_current;
                    pc_load <= 1'b1;
                    pc_write <= 1'b1;
                    done <= 1'b1;
                    state <= STATE_IDLE;
                    pc_load <= 1'b0;
                    pc_write <= 1'b0;
                end

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

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
