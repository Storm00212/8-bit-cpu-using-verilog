// ============================================================================
// CPU Complete Testbench - Real-Time Monitoring
// ============================================================================
// 
// This testbench provides real-time terminal output showing:
// - Clock cycles
// - All bus signals (data, address, control)
// - Register contents (ACC, X, Y, PC, SP, IR, Flags)
// - Status flags
// - Memory content
// - Current instruction
// ============================================================================

`timescale 1ns/1ps

`include "instructions.vh"

module cpu_tb;
    
    // CPU signals
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
    
    // Memory
    reg [7:0] ram [0:65535];
    reg [7:0] rom [0:65535];
    reg [7:0] mem_data_out;
    
    always @(addr_bus) begin
        if (addr_bus < 16'h0100) begin
            mem_data_out = rom[addr_bus];
        end else begin
            mem_data_out = ram[addr_bus];
        end
    end
    
    always @(posedge clk) begin
        if (mem_write && addr_bus >= 16'h0100) begin
            ram[addr_bus] <= acc_out;
        end
    end
    
    always #5 clk = ~clk;
    
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
        .halt(halt)
    );
    
    assign data_bus = (mem_read) ? mem_data_out : 8'hZZ;
    
    integer clock_cycles = 0;
    integer i;
    
    // Helper task to print separator
    task print_sep;
        begin
            $write("\n");
            for (i = 0; i < 80; i = i + 1) $write("=");
            $write("\n");
        end
    endtask
    
    // Main display task
    task display_state;
        input [79:0] phase;
        begin
            clock_cycles = clock_cycles + 1;
            print_sep;
            $write("  CLOCK CYCLE: %0d  |  PHASE: %s\n", clock_cycles, phase);
            print_sep;
            
            $write("--- BUS SIGNALS ---\n");
            $write("  ADDR: 0x%04h  DATA: 0x%02h  MEM_RD: %b  MEM_WR: %b\n", 
                   addr_bus, data_bus, mem_read, mem_write);
            
            $write("--- REGISTERS ---\n");
            $write("  PC:  0x%04h  ACC: 0x%02h  X: 0x%02h  Y: 0x%02h\n", 
                   pc_out, acc_out, x_out, y_out);
            
            $write("--- FLAGS ---\n");
            $write("  FLAGS: 0x%02h  [C=%b Z=%b N=%b V=%b]\n", 
                   flags_out, flags_out[0], flags_out[1], flags_out[2], flags_out[3]);
            
            $write("--- MEMORY ---\n");
            $write("  ROM[0x%04h] = 0x%02h\n", addr_bus, rom[addr_bus]);
            
            print_sep;
            $write("\n");
        end
    endtask
    
    initial begin
        $timeformat(-9, 0, " ns", 8);
        
        print_sep;
        $write("           8-BIT CPU SIMULATION - REAL-TIME MONITOR\n");
        print_sep;
        
        clk = 0;
        reset = 0;
        
        // Load test program
        $write("Loading test program...\n\n");
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h55;
        rom[16'h0002] = `OPCODE_LDX_IMM;
        rom[16'h0003] = 8'hAA;
        rom[16'h0004] = `OPCODE_ADD_IMM;
        rom[16'h0005] = 8'h0A;
        rom[16'h0006] = `OPCODE_NOP;
        for (i = 16'h0007; i < 16'h0100; i = i + 1) rom[i] = `OPCODE_NOP;
        
        $write("Program:\n");
        $write("  0x0000: LDA #0x55\n");
        $write("  0x0002: LDX #0xAA\n");
        $write("  0x0004: ADD #0x0A\n");
        $write("  0x0006: NOP\n\n");
        
        // Reset
        print_sep;
        $write("APPLYING RESET\n");
        print_sep;
        reset = 1;
        #10;
        reset = 0;
        #10;
        
        display_state("INITIAL STATE");
        
        // Execute instructions
        print_sep;
        $write("EXECUTING INSTRUCTIONS\n");
        print_sep;
        
        repeat (15) begin
            @(posedge clk);
            #2;
            display_state("EXECUTE");
        end
        
        print_sep;
        $write("SIMULATION COMPLETE\n");
        $write("Total clock cycles: %0d\n", clock_cycles);
        print_sep;
        
        #100;
        $finish;
    end
    
    // Timeout
    initial begin
        #50000;
        $write("\nTIMEOUT\n");
        $finish;
    end
    
endmodule
