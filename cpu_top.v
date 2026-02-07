// ============================================================================
// CPU Top-Level Module
// ============================================================================
// 
// The CPU Top-Level Module integrates all the individual components of the
// 8-bit CPU into a complete, functional processor.
// ============================================================================

`include "instructions.vh"

module cpu_top (
    // External Interface
    input wire clk,           
    input wire reset,         
    
    // Bus Interface
    inout wire [7:0] data_bus,      
    output wire [15:0] addr_bus,     
    output wire mem_read,            
    output wire mem_write,           
    output wire halt,
    
    // Debug/Status Outputs
    output wire [7:0] acc_out,      
    output wire [15:0] pc_out,      
    output wire [7:0] flags_out,     
    output wire [7:0] x_out,         
    output wire [7:0] y_out,
    
    // Debug signals (for monitoring)
    output wire [7:0] debug_rom_data,
    output wire [7:0] debug_data_bus_in
);

    // =========================================================================
    // Signal Declarations
    // =========================================================================
    
    wire acc_write, x_write, y_write;
    wire pc_write, pc_inc, pc_load;
    wire sp_write, ir_write, flags_write;
    wire alu_done;
    wire done;
    wire [3:0] alu_operation;
    wire [15:0] pc_direct;
    
    wire [7:0] acc_reg, x_reg, y_reg;
    wire [7:0] sp_reg, ir_reg, flags_reg;
    wire [15:0] pc_reg;
    reg [15:0] pc_current;
    
    wire [7:0] rom_data_out;
    wire [7:0] ram_data_out;
    wire [15:0] mem_addr;
    wire internal_mem_read;
    
    wire [7:0] alu_result;
    wire [7:0] alu_flags;
    
    // =========================================================================
    // PC Register
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
    
    wire select_rom = (addr_bus[15:8] == 8'h00) && internal_mem_read;
    wire select_ram = (addr_bus[15:8] != 8'h00) && internal_mem_read;
    
    assign mem_read = internal_mem_read;
    
    // Data bus driver
    assign data_bus = select_rom ? rom_data_out :
                      select_ram ? ram_data_out : 8'hZZ;
    
    // Debug outputs
    assign debug_rom_data = rom_data_out;
    assign debug_data_bus_in = data_bus;
    
    // =========================================================================
    // Output Assignments
    // =========================================================================
    
    assign acc_out = acc_reg;
    assign pc_out = pc_reg;
    assign flags_out = flags_reg;
    assign x_out = x_reg;
    assign y_out = y_reg;
    assign halt = 1'b0;
    
    // =========================================================================
    // Debug Monitor
    // =========================================================================
    
    always @(posedge clk) begin
        if (reset) begin
            $display("CPU Reset");
        end else begin
            if (done) begin
                $display("PC=%h: opcode=%h, ACC=%h, X=%h, Y=%h", 
                         pc_reg, data_bus, acc_reg, x_reg, y_reg);
                $display("  DEBUG: rom_data=%h, sel_rom=%b, mem_read=%b", 
                         rom_data_out, select_rom, internal_mem_read);
            end
        end
    end

endmodule
