// ============================================================================
// CPU Testbench - Simple Version
// ============================================================================
// 
// Uses $readmemb to load ROM from file
// ============================================================================

`timescale 1ns/1ps

`include "instructions.vh"

module cpu_tb;
    
    // Testbench signals
    reg clk;
    reg reset;
    wire [7:0] data_bus;
    wire [15:0] addr_bus;
    wire mem_read;
    wire mem_write;
    wire [7:0] acc_out;
    wire [15:0] pc_out;
    wire [7:0] flags_out;
    wire [7:0] x_out;
    wire [7:0] y_out;
    wire halt;
    
    // ROM/RAM interfaces
    output wire [7:0] rom_addr;
    input wire [7:0] rom_data;
    output wire [15:0] ram_addr;
    input wire [7:0] ram_data;
    
    // ROM/RAM arrays
    reg [7:0] rom_array [0:255];
    reg [7:0] ram_array [0:65535];
    
    // ROM instance
    wire [7:0] rom_data_wire;
    assign rom_data = rom_data_wire;
    assign rom_array[rom_addr] = rom_data_wire;  // For reference
    
    // RAM instance  
    wire [7:0] ram_data_wire;
    assign ram_data = ram_data_wire;
    assign ram_array[ram_addr] = ram_data_wire;  // For reference
    
    // ROM behavior
    assign rom_data_wire = rom_array[rom_addr];
    
    // RAM behavior (synchronous write)
    reg [7:0] ram_internal [0:65535];
    assign ram_data_wire = ram_internal[ram_addr];
    always @(posedge clk) begin
        if (mem_write) begin
            ram_internal[ram_addr] <= acc_out;
        end
    end
    
    // CPU instance
    cpu_top cpu (
        .clk(clk),
        .reset(reset),
        .data_bus(data_bus),
        .addr_bus(addr_bus),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .acc_out(acc_out),
        .pc_out(pc_out),
        .flags_out(flags_out),
        .x_out(x_out),
        .y_out(y_out),
        .halt(halt),
        .rom_addr(rom_addr),
        .rom_data(rom_data_wire),
        .ram_addr(ram_addr),
        .ram_data(ram_data_wire)
    );
    
    // Clock generation
    integer clock_cycles = 0;
    integer i;
    
    initial begin
        $timeformat(-9, 0, " ns", 8);
        
        $write("\n");
        for (i = 0; i < 80; i = i + 1) $write("=");
        $write("\n");
        $write("                    8-BIT CPU SIMULATION\n");
        for (i = 0; i < 80; i = i + 1) $write("=");
        $write("\n\n");
        
        clk = 0;
        reset = 0;
        
        // Initialize ROM with test program
        $write("Loading test program...\n\n");
        rom_array[8'h00] = `OPCODE_LDA_IMM;
        rom_array[8'h01] = 8'h55;
        rom_array[8'h02] = `OPCODE_LDX_IMM;
        rom_array[8'h03] = 8'hAA;
        rom_array[8'h04] = `OPCODE_LDY_IMM;
        rom_array[8'h05] = 8'h33;
        rom_array[8'h06] = `OPCODE_ADD_IMM;
        rom_array[8'h07] = 8'h0A;
        rom_array[8'h08] = `OPCODE_SUB_IMM;
        rom_array[8'h09] = 8'h05;
        rom_array[8'h0A] = `OPCODE_AND_IMM;
        rom_array[8'h0B] = 8'hFF;
        rom_array[8'h0C] = `OPCODE_OR_IMM;
        rom_array[8'h0D] = 8'h0F;
        rom_array[8'h0E] = `OPCODE_XOR_IMM;
        rom_array[8'h0F] = 8'hFF;
        rom_array[8'h10] = `OPCODE_NOT;
        rom_array[8'h11] = `OPCODE_INC;
        rom_array[8'h12] = `OPCODE_DEC;
        rom_array[8'h13] = `OPCODE_NOP;
        for (i = 8'h14; i < 8'hFF; i = i + 1) rom_array[i] = `OPCODE_NOP;
        
        for (i = 16'h0100; i < 16'hFFFF; i = i + 1) ram_internal[i] = 8'h00;
        
        $write("Test Program:\n");
        $write("  0x0000: LDA #0x55  ; Load ACC = 85\n");
        $write("  0x0002: LDX #0xAA  ; Load X = 170\n");
        $write("  0x0004: LDY #0x33  ; Load Y = 51\n");
        $write("  0x0006: ADD #0x0A  ; ADD 10 to ACC\n");
        $write("  0x0008: SUB #0x05  ; SUB 5 from ACC\n");
        $write("  0x000A: AND #0xFF  ; AND with 255\n");
        $write("  0x000C: OR  #0x0F  ; OR with 15\n");
        $write("  0x000E: XOR #0xFF  ; XOR with 255\n");
        $write("  0x0010: NOT        ; NOT ACC\n");
        $write("  0x0011: INC        ; INC ACC\n");
        $write("  0x0012: DEC        ; DEC ACC\n");
        $write("  0x0013: NOP        ; Halt\n\n");
        
        // Reset
        $write("Applying reset...\n");
        reset = 1;
        #10;
        reset = 0;
        #10;
        
        // Execute instructions
        $write("\nExecuting instructions...\n\n");
        
        repeat (25) begin
            @(posedge clk);
            #1;
            clock_cycles = clock_cycles + 1;
            $display("CYCLE %0d: PC=%04h DATA=%02h ACC=%02h X=%02h Y=%02h MEM_RD=%b MEM_WR=%b",
                     clock_cycles, addr_bus, data_bus, acc_out, x_out, y_out, mem_read, mem_write);
        end
        
        // Summary
        $write("\n");
        for (i = 0; i < 60; i = i + 1) $write("=");
        $write("\n");
        $write("SIMULATION COMPLETE\n");
        $write("Total clock cycles: %0d\n", clock_cycles);
        $write("Final ACC: 0x%02h  (Expected: 0x5F = 95)\n", acc_out);
        $write("Final X:   0x%02h  (Expected: 0xAA = 170)\n", x_out);
        $write("Final Y:   0x%02h  (Expected: 0x33 = 51)\n", y_out);
        for (i = 0; i < 60; i = i + 1) $write("=");
        $write("\n\n");
        
        #100;
        $finish;
    end
    
    always #5 clk = ~clk;
    
    initial begin
        #100000;
        $write("\nTIMEOUT\n");
        $finish;
    end
    
endmodule
