// ============================================================
// CPU Top-Level Module
// Integrates ALU, Register File, RAM, ROM, and Control Unit
// ============================================================

`include "instructions.vh"

module cpu_top (
    input wire        clk,           // System clock
    input wire        reset,         // Reset signal
    output wire [7:0] data_bus,      // 8-bit data bus (bidirectional)
    output wire [15:0] addr_bus,    // 16-bit address bus
    output wire       mem_read,      // Memory read enable
    output wire       mem_write,     // Memory write enable
    output wire [7:0] acc_out,       // Accumulator output (debug)
    output wire [15:0] pc_out,       // Program counter output (debug)
    output wire [7:0] flags_out,     // Flags output (debug)
    output wire [7:0] x_out,        // X register output (debug)
    output wire [7:0] y_out,        // Y register output (debug)
    output wire       halt           // CPU halt status
);

    // ================ Internal Signals ================
    
    // Control signals
    wire        acc_write, x_write, y_write;
    wire        pc_write, pc_inc, pc_load;
    wire        sp_write, ir_write, flags_write;
    wire        alu_done;
    wire        done;
    wire [3:0]  alu_operation;
    wire [15:0] pc_direct;
    wire [7:0]  opcode_out;
    wire [7:0]  opcode_to_cu;
    
    // Data signals
    wire [7:0]  acc_reg, x_reg, y_reg, sp_reg;
    wire [7:0]  ir_reg, flags_reg;
    wire [15:0] pc_reg;
    
    // Memory interface
    wire [7:0]  ram_data_out, rom_data_out;
    wire        ram_ready;
    wire [15:0] mem_addr;
    
    // ALU signals
    wire [7:0]  alu_result;
    wire [7:0]  alu_flags;
    
    // Memory data source selection
    reg [7:0]   mem_data_in;
    wire        mem_data_from_ram, mem_data_from_rom;

    // ================ Module Instances ================
    
    // Register File
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
    
    // ALU
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
    
    // Control Unit
    control_unit cu (
        .clk(clk),
        .reset(reset),
        .opcode(data_bus),
        .flags_in(flags_reg),
        .alu_done(alu_done),
        .data_bus(data_bus),
        .pc_current(pc_reg),
        .opcode_out(opcode_out),
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
        .mem_read(mem_data_from_rom),
        .mem_write(mem_write),
        .mem_addr(mem_addr),
        .done(done)
    );
    
    // RAM
    ram ram_module (
        .clk(clk),
        .reset(reset),
        .addr(addr_bus),
        .data_in(acc_reg),  // Write accumulator to RAM
        .write_enable(mem_write),
        .read_enable(mem_data_from_ram),
        .data_out(ram_data_out),
        .ready(ram_ready)
    );
    
    // ROM
    rom rom_module (
        .addr(addr_bus),
        .data_out(rom_data_out)
    );
    
    // ================ Memory Interface Logic ================
    
    // Determine data source (ROM for instruction fetch, RAM for data)
    assign mem_data_from_rom = (addr_bus[15:8] == 8'h00);  // ROM at 0x0000-0x00FF
    assign mem_data_from_ram = (addr_bus[15:8] != 8'h00);  // RAM elsewhere
    
    // Data bus multiplexer
    always @(*) begin
        if (mem_data_from_rom) begin
            mem_data_in = rom_data_out;
        end else if (mem_data_from_ram) begin
            mem_data_in = ram_data_out;
        end else begin
            mem_data_in = 8'hZZ;
        end
    end
    
    // Data bus output (bidirectional)
    assign data_bus = (mem_write) ? acc_reg : 8'hZZ;
    
    // Memory read signal
    assign mem_read = mem_data_from_rom || mem_data_from_ram;
    
    // ================ Output Assignments ================
    
    assign acc_out = acc_reg;
    assign pc_out = pc_reg;
    assign flags_out = flags_reg;
    assign x_out = x_reg;
    assign y_out = y_reg;
    
    // Halt when done signal is active (single instruction execution)
    assign halt = 1'b0;  // CPU runs continuously
    
    // ================ Debug Monitor ================
    
    // Debug: Display register contents
    always @(posedge clk) begin
        if (reset) begin
            $display("CPU Reset - PC=%h, ACC=%h, X=%h, Y=%h, FLAGS=%h", 
                     pc_reg, acc_reg, x_reg, y_reg, flags_reg);
        end else begin
            // Print on instruction completion
            if (done) begin
                $display("PC=%h: opcode=%h, ACC=%h, X=%h, Y=%h, FLAGS=%h",
                         pc_reg, data_bus, acc_reg, x_reg, y_reg, flags_reg);
            end
        end
    end
    
endmodule
