// ============================================================
// Register File Module
// Contains all CPU registers: Accumulator, X, Y, PC, SP, IR, Flags
// ============================================================

`include "instructions.vh"

module register_file (
    input wire        clk,              // Clock
    input wire        reset,            // Reset
    input wire [7:0]  data_in,          // Data to write to register
    input wire        acc_write,        // Write enable for accumulator
    input wire        x_write,          // Write enable for X register
    input wire        y_write,          // Write enable for Y register
    input wire        pc_write,         // Write enable for PC
    input wire        sp_write,         // Write enable for SP
    input wire        ir_write,         // Write enable for IR
    input wire        flags_write,      // Write enable for flags
    input wire [7:0]  pc_direct,        // Direct PC value (for jumps)
    input wire        pc_inc,           // Increment PC
    input wire        pc_load,          // Load PC from data bus
    output reg [7:0]  acc_out,          // Accumulator output
    output reg [7:0]  x_out,            // X register output
    output reg [7:0]  y_out,            // Y register output
    output reg [15:0] pc_out,           // Program counter output
    output reg [7:0]  sp_out,           // Stack pointer output
    output reg [7:0]  ir_out,           // Instruction register output
    output reg [7:0]  flags_out,        // Flags register output
    output reg [15:0] addr_bus          // Address bus (for memory operations)
);

    // Internal registers
    reg [7:0] acc;
    reg [7:0] x_reg;
    reg [7:0] y_reg;
    reg [15:0] pc;
    reg [7:0] sp;
    reg [7:0] ir;
    reg [7:0] flags;

    // Flags
    wire C, Z, N, V;
    assign C = flags[`FLAG_CARRY];
    assign Z = flags[`FLAG_ZERO];
    assign N = flags[`FLAG_SIGN];
    assign V = flags[`FLAG_OVERFLOW];

    // Stack pointer (8-bit, uses page 1 for stack)
    // Stack grows downward from 0x01FF to 0x0100
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            acc <= 8'h00;
            x_reg <= 8'h00;
            y_reg <= 8'h00;
            pc <= 16'h0000;
            sp <= 8'hFF;  // Start at top of stack page
            ir <= 8'h00;
            flags <= 8'h00;
            acc_out <= 8'h00;
            x_out <= 8'h00;
            y_out <= 8'h00;
            pc_out <= 16'h0000;
            sp_out <= 8'hFF;
            ir_out <= 8'h00;
            flags_out <= 8'h00;
            addr_bus <= 16'h0000;
        end else begin
            // Write operations
            if (acc_write) acc <= data_in;
            if (x_write) x_reg <= data_in;
            if (y_write) y_reg <= data_in;
            if (sp_write) sp <= data_in;

            // PC operations
            if (pc_write) begin
                if (pc_direct[15:8] != 8'h00) begin
                    pc <= {pc_direct[15:8], data_in};
                end else begin
                    pc <= {8'h00, data_in};
                end
            end else if (pc_inc) begin
                pc <= pc + 16'h0001;
            end else if (pc_load) begin
                pc <= {pc_direct[15:8], data_in};
            end

            // IR write
            if (ir_write) ir <= data_in;

            // Flags write
            if (flags_write) flags <= data_in;

            // Update outputs
            acc_out <= acc;
            x_out <= x_reg;
            y_out <= y_reg;
            pc_out <= pc;
            sp_out <= sp;
            ir_out <= ir;
            flags_out <= flags;

            // Address bus (combine high and low bytes from different sources)
            // For now, use PC for instruction fetch
            addr_bus <= pc;
        end
    end

    // Push to stack (decrement SP, then write)
    task push;
        input [7:0] value;
        begin
            sp <= sp - 1;
            // This would be handled by memory controller
        end
    endtask

    // Pull from stack (read, then increment SP)
    task pull;
        output [7:0] value;
        begin
            value = 8'h00;  // Would be read from memory
            sp <= sp + 1;
        end
    endtask

endmodule
