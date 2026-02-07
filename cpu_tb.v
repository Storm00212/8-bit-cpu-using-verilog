// ============================================================================
// CPU Testbench - Real-Time Monitoring
// ============================================================================
// 
// Displays: Clock cycles, buses, registers, flags, memory, and instructions
// ============================================================================

`timescale 1ns/1ps

`include "instructions.vh"

module cpu_tb;
    
    reg clk;
    reg reset;
    wire [7:0] data_bus;
    wire [15:0] addr_bus;
    wire [7:0] acc_out;
    wire [15:0] pc_out;
    wire [7:0] flags_out;
    wire [7:0] x_out;
    wire [7:0] y_out;
    wire halt;
    
    wire mem_read;
    wire mem_write;
    
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
        if (mem_write) begin
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
    
    assign data_bus = (mem_read) ? mem_data_out : 8'bZ;
    
    integer clock_cycles = 0;
    integer i;
    
    task print_state;
        input [79:0] phase;
        begin
            clock_cycles = clock_cycles + 1;
            $write("\n");
            $write("================================================================================\n");
            $write("  CLOCK CYCLE: %0d  |  %s\n", clock_cycles, phase);
            $write("================================================================================\n");
            
            $write("--- BUS SIGNALS ---\n");
            $write("  CLK:    %b  |  ADDR: 0x%04h  |  DATA: 0x%02h\n", clk, addr_bus, data_bus);
            $write("  MEM_RD: %b  |  MEM_WR: %b\n", mem_read, mem_write);
            
            $write("--- REGISTERS ---\n");
            $write("  PC:  0x%04h  |  ACC: 0x%02h  |  X: 0x%02h  |  Y: 0x%02h\n", 
                   pc_out, acc_out, x_out, y_out);
            
            $write("--- FLAGS ---\n");
            $write("  FLAGS: 0x%02h  [C=%b Z=%b N=%b V=%b]\n", 
                   flags_out, flags_out[0], flags_out[1], flags_out[2], flags_out[3]);
            
            $write("--- MEMORY ---\n");
            $write("  ROM[0x%04h] = 0x%02h", addr_bus, rom[addr_bus]);
            if (rom[addr_bus] == `OPCODE_NOP) $write("  [NOP]");
            else if (rom[addr_bus] == `OPCODE_LDA_IMM) $write("  [LDA #imm]");
            else if (rom[addr_bus] == `OPCODE_LDX_IMM) $write("  [LDX #imm]");
            else if (rom[addr_bus] == `OPCODE_ADD_IMM) $write("  [ADD #imm]");
            else if (rom[addr_bus] == `OPCODE_SUB_IMM) $write("  [SUB #imm]");
            else if (rom[addr_bus] == `OPCODE_AND_IMM) $write("  [AND #imm]");
            else if (rom[addr_bus] == `OPCODE_OR_IMM) $write("  [OR #imm]");
            else if (rom[addr_bus] == `OPCODE_XOR_IMM) $write("  [XOR #imm]");
            else if (rom[addr_bus] == `OPCODE_NOT) $write("  [NOT]");
            else if (rom[addr_bus] == `OPCODE_INC) $write("  [INC]");
            else if (rom[addr_bus] == `OPCODE_DEC) $write("  [DEC]");
            else if (rom[addr_bus] == `OPCODE_BEQ) $write("  [BEQ]");
            else if (rom[addr_bus] == `OPCODE_BNE) $write("  [BNE]");
            else if (rom[addr_bus] == `OPCODE_BRA) $write("  [BRA]");
            $write("\n");
            
            $write("\n");
        end
    endtask
    
    initial begin
        $timeformat(-9, 0, " ns", 8);
        
        $write("\n");
        for (i = 0; i < 80; i = i + 1) $write("=");
        $write("\n");
        $write("                    8-BIT CPU SIMULATION - REAL-TIME MONITOR\n");
        for (i = 0; i < 80; i = i + 1) $write("=");
        $write("\n\n");
        
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
        rom[16'h0006] = `OPCODE_SUB_IMM;
        rom[16'h0007] = 8'h05;
        rom[16'h0008] = `OPCODE_AND_IMM;
        rom[16'h0009] = 8'hFF;
        rom[16'h000A] = `OPCODE_OR_IMM;
        rom[16'h000B] = 8'h0F;
        rom[16'h000C] = `OPCODE_XOR_IMM;
        rom[16'h000D] = 8'hFF;
        rom[16'h000E] = `OPCODE_NOT;
        rom[16'h000F] = `OPCODE_NOP;
        for (i = 16'h0010; i < 16'h0100; i = i + 1) rom[i] = `OPCODE_NOP;
        
        $write("Test Program:\n");
        $write("  0x0000: LDA #0x55  ; Load ACC = 85\n");
        $write("  0x0002: LDX #0xAA  ; Load X = 170\n");
        $write("  0x0004: ADD #0x0A  ; ADD 10 to ACC\n");
        $write("  0x0006: SUB #0x05  ; SUB 5 from ACC\n");
        $write("  0x0008: AND #0xFF  ; AND with 255\n");
        $write("  0x000A: OR  #0x0F  ; OR with 15\n");
        $write("  0x000C: XOR #0xFF  ; XOR with 255\n");
        $write("  0x000E: NOT        ; NOT ACC\n");
        $write("  0x000F: NOP        ; Halt\n\n");
        
        // Reset
        for (i = 0; i < 80; i = i + 1) $write("-");
        $write("\nAPPLYING RESET\n");
        for (i = 0; i < 80; i = i + 1) $write("-");
        $write("\n");
        reset = 1;
        #10;
        reset = 0;
        #10;
        print_state("INITIAL STATE");
        
        // Execute instructions
        for (i = 0; i < 80; i = i + 1) $write("-");
        $write("\nEXECUTING INSTRUCTIONS\n");
        for (i = 0; i < 80; i = i + 1) $write("-");
        $write("\n");
        
        repeat (20) begin
            @(posedge clk);
            #1;
            print_state("EXECUTE");
        end
        
        // Summary
        for (i = 0; i < 80; i = i + 1) $write("=");
        $write("\n");
        $write("SIMULATION COMPLETE\n");
        $write("Total clock cycles: %0d\n", clock_cycles);
        for (i = 0; i < 80; i = i + 1) $write("=");
        $write("\n\n");
        
        #100;
        $finish;
    end
    
    initial begin
        #50000;
        $write("\nTIMEOUT - Simulation took too long\n");
        $finish;
    end
    
endmodule
