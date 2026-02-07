// ============================================================================
// Control Unit - Fixed FSM Implementation
// ============================================================================
// 
// Fixed issues:
// 1. Added proper signal registration
// 2. Simplified state machine for immediate operations
// 3. Proper DONE signal handling
// ============================================================================

`include "instructions.vh"

module control_unit (
    input wire clk,
    input wire reset,
    input wire [7:0] opcode,
    input wire [7:0] flags_in,
    input wire alu_done,
    input wire [7:0] data_bus,
    input wire [15:0] pc_current,
    
    output reg [3:0] alu_operation,
    output reg acc_write,
    output reg x_write,
    output reg y_write,
    output reg pc_write,
    output reg pc_inc,
    output reg pc_load,
    output reg [15:0] pc_direct,
    output reg sp_write,
    output reg ir_write,
    output reg flags_write,
    output reg mem_read,
    output reg mem_write,
    output reg [15:0] mem_addr,
    output reg done
);

    // FSM states
    localparam STATE_IDLE    = 3'b000;
    localparam STATE_FETCH  = 3'b001;
    localparam STATE_DECODE = 3'b010;
    localparam STATE_EXEC   = 3'b011;
    localparam STATE_WRITE  = 3'b100;

    // ALU operations
    localparam OP_ADD = 4'd0;
    localparam OP_SUB = 4'd1;
    localparam OP_AND = 4'd4;
    localparam OP_OR  = 4'd5;
    localparam OP_XOR = 4'd6;
    localparam OP_NOT = 4'd7;
    localparam OP_INC = 4'd12;
    localparam OP_DEC = 4'd13;

    // FSM state and registered values
    reg [2:0] state;
    reg [7:0] opcode_reg;
    reg [7:0] operand_reg;
    reg [7:0] opcode_fetched;
    reg [2:0] cycle_count;

    // Flag bits
    wire Z = flags_in[1];
    wire N = flags_in[2];
    wire C = flags_in[0];

    // Main FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all outputs
            state <= STATE_IDLE;
            opcode_reg <= 8'd0;
            opcode_fetched <= 8'd0;
            operand_reg <= 8'd0;
            cycle_count <= 3'd0;
            
            alu_operation <= 4'd0;
            acc_write <= 1'b0;
            x_write <= 1'b0;
            y_write <= 1'b0;
            pc_write <= 1'b0;
            pc_inc <= 1'b0;
            pc_load <= 1'b0;
            pc_direct <= 16'd0;
            sp_write <= 1'b0;
            ir_write <= 1'b0;
            flags_write <= 1'b0;
            mem_read <= 1'b0;
            mem_write <= 1'b0;
            mem_addr <= 16'd0;
            done <= 1'b1;
        end
        else begin
            // Clear strobe signals (they are pulse-only)
            acc_write <= 1'b0;
            x_write <= 1'b0;
            y_write <= 1'b0;
            pc_write <= 1'b0;
            pc_load <= 1'b0;
            mem_write <= 1'b0;
            done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    // Start instruction fetch
                    state <= STATE_FETCH;
                    mem_addr <= pc_current;
                    mem_read <= 1'b1;
                    pc_inc <= 1'b1;
                end

                STATE_FETCH: begin
                    // Capture opcode from data bus
                    opcode_fetched <= data_bus;
                    ir_write <= 1'b1;
                    state <= STATE_DECODE;
                end

                STATE_DECODE: begin
                    // Clear memory read, decode opcode
                    mem_read <= 1'b0;
                    ir_write <= 1'b0;
                    opcode_reg <= opcode_fetched;
                    cycle_count <= 3'd0;
                    state <= STATE_EXEC;
                end

                STATE_EXEC: begin
                    // Execute instruction based on opcode
                    case (opcode_fetched)
                        `OPCODE_NOP: begin
                            done <= 1'b1;
                            state <= STATE_IDLE;
                        end

                        `OPCODE_LDA_IMM: begin
                            // Next byte is immediate value
                            mem_addr <= pc_current + 16'd1;
                            mem_read <= 1'b1;
                            state <= STATE_WRITE;
                        end

                        `OPCODE_LDX_IMM: begin
                            mem_addr <= pc_current + 16'd1;
                            mem_read <= 1'b1;
                            state <= STATE_WRITE;
                        end

                        `OPCODE_LDY_IMM: begin
                            mem_addr <= pc_current + 16'd1;
                            mem_read <= 1'b1;
                            state <= STATE_WRITE;
                        end

                        `OPCODE_ADD_IMM: begin
                            mem_addr <= pc_current + 16'd1;
                            mem_read <= 1'b1;
                            alu_operation <= OP_ADD;
                            state <= STATE_WRITE;
                        end

                        `OPCODE_SUB_IMM: begin
                            mem_addr <= pc_current + 16'd1;
                            mem_read <= 1'b1;
                            alu_operation <= OP_SUB;
                            state <= STATE_WRITE;
                        end

                        `OPCODE_AND_IMM: begin
                            mem_addr <= pc_current + 16'd1;
                            mem_read <= 1'b1;
                            alu_operation <= OP_AND;
                            state <= STATE_WRITE;
                        end

                        `OPCODE_OR_IMM: begin
                            mem_addr <= pc_current + 16'd1;
                            mem_read <= 1'b1;
                            alu_operation <= OP_OR;
                            state <= STATE_WRITE;
                        end

                        `OPCODE_XOR_IMM: begin
                            mem_addr <= pc_current + 16'd1;
                            mem_read <= 1'b1;
                            alu_operation <= OP_XOR;
                            state <= STATE_WRITE;
                        end

                        `OPCODE_INC: begin
                            alu_operation <= OP_INC;
                            acc_write <= 1'b1;
                            done <= 1'b1;
                            state <= STATE_IDLE;
                        end

                        `OPCODE_DEC: begin
                            alu_operation <= OP_DEC;
                            acc_write <= 1'b1;
                            done <= 1'b1;
                            state <= STATE_IDLE;
                        end

                        `OPCODE_NOT: begin
                            alu_operation <= OP_NOT;
                            acc_write <= 1'b1;
                            done <= 1'b1;
                            state <= STATE_IDLE;
                        end

                        `OPCODE_BEQ: begin
                            if (Z) begin
                                pc_direct <= pc_current;
                                pc_load <= 1'b1;
                            end
                            done <= 1'b1;
                            state <= STATE_IDLE;
                        end

                        `OPCODE_BNE: begin
                            if (~Z) begin
                                pc_direct <= pc_current;
                                pc_load <= 1'b1;
                            end
                            done <= 1'b1;
                            state <= STATE_IDLE;
                        end

                        `OPCODE_BRA: begin
                            pc_direct <= pc_current;
                            pc_load <= 1'b1;
                            done <= 1'b1;
                            state <= STATE_IDLE;
                        end

                        default: begin
                            done <= 1'b1;
                            state <= STATE_IDLE;
                        end
                    endcase
                end

                STATE_WRITE: begin
                    // Complete the operation with the operand
                    mem_read <= 1'b0;
                    
                    case (opcode_fetched)
                        `OPCODE_LDA_IMM: begin
                            acc_write <= 1'b1;
                        end

                        `OPCODE_LDX_IMM: begin
                            x_write <= 1'b1;
                        end

                        `OPCODE_LDY_IMM: begin
                            y_write <= 1'b1;
                        end

                        `OPCODE_ADD_IMM,
                        `OPCODE_SUB_IMM,
                        `OPCODE_AND_IMM,
                        `OPCODE_OR_IMM,
                        `OPCODE_XOR_IMM: begin
                            acc_write <= 1'b1;
                        end
                    endcase
                    
                    done <= 1'b1;
                    state <= STATE_IDLE;
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
