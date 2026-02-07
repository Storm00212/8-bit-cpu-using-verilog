// ============================================================================
// CPU Top-Level Module
// ============================================================================
// 
// The CPU Top-Level Module integrates all the individual components of the
// 8-bit CPU into a complete, functional processor. It provides the external
// interface and handles the interconnection between components.
// 
// Component Connections:
// - Control Unit orchestrates all operations
// - Register File stores CPU state
// - ALU performs calculations
// - External ROM for program code
// - External RAM for data
// 
// Bus Architecture:
// - 8-bit bidirectional data bus
// - 16-bit unidirectional address bus
// ============================================================================

`include "instructions.vh"

module cpu_top (
    // External Interface
    input wire clk,           // System clock - all operations synchronous
    input wire reset,         // Asynchronous reset - initializes CPU
    
    // Bus Interface
    inout wire [7:0] data_bus,      // 8-bit bidirectional data bus
    output wire [15:0] addr_bus,     // 16-bit address bus (output only)
    output wire mem_read,            // Memory read enable
    output wire mem_write,           // Memory write enable
    
    // Debug/Status Outputs
    output wire [7:0] acc_out,      // Accumulator value (debug)
    output wire [15:0] pc_out,      // Program counter value (debug)
    output wire [7:0] flags_out,     // Flags register (debug)
    output wire [7:0] x_out,         // X register value (debug)
    output wire [7:0] y_out,         // Y register value (debug)
    output wire halt                 // CPU halt status
);

    // =========================================================================
    // Signal Declarations
    // =========================================================================
    
    // -------------------- Control Signals --------------------
    wire acc_write, x_write, y_write;      // Register write enables
    wire pc_write, pc_inc, pc_load;       // PC control signals
    wire sp_write, ir_write, flags_write;  // Register write enables
    wire alu_done;                          // ALU operation complete
    wire done;                              // Instruction complete
    wire [3:0] alu_operation;              // ALU operation code
    wire [15:0] pc_direct;                 // Direct PC value for jumps
    
    // -------------------- Data Signals --------------------
    wire [7:0] acc_reg, x_reg, y_reg;      // Register values
    wire [7:0] sp_reg, ir_reg, flags_reg; // Register values
    wire [15:0] pc_reg;                   // Program counter
    reg [15:0] pc_current;               // Current PC value (registered)
    
    // -------------------- Memory Interface --------------------
    wire [7:0] rom_data_out;              // ROM data output
    wire [7:0] ram_data_out;              // RAM data output
    wire [15:0] mem_addr;                  // Memory address
    wire internal_mem_read;               // Internal memory read (before address decode)
    
    // -------------------- ALU Signals --------------------
    wire [7:0] alu_result;                 // ALU result output
    wire [7:0] alu_flags;                  // ALU flags output
    
    // =========================================================================
    // PC Register - Captures PC value for control unit
    // =========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_current <= 16'd0;
        end else begin
            pc_current <= pc_reg;
        end
    end
    
    // =========================================================================
    // Module Instantiations
    // =========================================================================
    
    // -------------------- Register File --------------------
    register_file reg_file (
        .clk(clk),
        .reset(reset),
        .data_in(data_bus),
        .acc_write(acc_write),
        .x_write(x_write),
        .y_write(y_write),
        .pc_write(pc_write),
        .sp_write(sp_write),
        .ir_write(ir_write),
        .flags_write(flags_write),
        .pc_direct(pc_direct),
        .pc_inc(pc_inc),
        .pc_load(pc_load),
        .acc_out(acc_reg),
        .x_out(x_reg),
        .y_out(y_reg),
        .pc_out(pc_reg),
        .sp_out(sp_reg),
        .ir_out(ir_reg),
        .flags_out(flags_reg),
        .addr_bus(addr_bus)
    );
    
    // -------------------- ALU (Arithmetic Logic Unit) --------------------
    alu alu_unit (
        .clk(clk),
        .reset(reset),
        .a(acc_reg),
        .b(data_bus),
        .operation(alu_operation),
        .result(alu_result),
        .flags(alu_flags),
        .done(alu_done)
    );
    
    // -------------------- Control Unit --------------------
    control_unit cu (
        .clk(clk),
        .reset(reset),
        .opcode(data_bus),
        .flags_in(flags_reg),
        .alu_done(alu_done),
        .data_bus(data_bus),
        .pc_current(pc_current),
        .alu_operation(alu_operation),
        .acc_write(acc_write),
        .x_write(x_write),
        .y_write(y_write),
        .pc_write(pc_write),
        .pc_inc(pc_inc),
        .pc_load(pc_load),
        .pc_direct(pc_direct),
        .sp_write(sp_write),
        .ir_write(ir_write),
        .flags_write(flags_write),
        .mem_read(internal_mem_read),
        .mem_write(mem_write),
        .mem_addr(mem_addr),
        .done(done)
    );
    
    // =========================================================================
    // Memory Interface Logic
    // =========================================================================
    
    // -------------------- Memory Source Selection --------------------
    // ROM is accessed for addresses in the first 256 bytes (0x0000-0x00FF)
    // RAM is accessed for all other addresses (0x0100-0xFFFF)
    
    wire select_rom = (addr_bus[15:8] == 8'h00) && internal_mem_read;
    wire select_ram = (addr_bus[15:8] != 8'h00) && internal_mem_read;
    
    // -------------------- Memory Read Enable --------------------
    assign mem_read = internal_mem_read;
    
    // -------------------- Data Bus Multiplexer --------------------
    // Drive data bus from ROM or RAM based on address
    assign data_bus = select_rom ? rom_data_out :
                      select_ram ? ram_data_out : 8'hZZ;
    
    // =========================================================================
    // Output Assignments
    // =========================================================================
    
    assign acc_out = acc_reg;
    assign pc_out = pc_reg;
    assign flags_out = flags_reg;
    assign x_out = x_reg;
    assign y_out = y_reg;
    
    // The CPU runs continuously in this implementation
    assign halt = 1'b0;
    
    // =========================================================================
    // Debug Monitor
    // =========================================================================
    
    always @(posedge clk) begin
        if (reset) begin
            $display("CPU Reset - PC=%h, ACC=%h, X=%h, Y=%h, FLAGS=%h", 
                     pc_reg, acc_reg, x_reg, y_reg, flags_reg);
        end else begin
            if (done) begin
                $display("PC=%h: opcode=%h, ACC=%h, X=%h, Y=%h, FLAGS=%h",
                         pc_reg, data_bus, acc_reg, x_reg, y_reg, flags_reg);
            end
        end
    end

endmodule
