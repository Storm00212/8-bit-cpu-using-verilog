// ============================================================================
// CPU Testbench - Simple Version
// ============================================================================
// 
// Testbench directly drives data bus based on address
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
    
    // ROM/RAM arrays
    reg [7:0] rom_array [0:65535];
    reg [7:0] ram_array [0:65535];
    
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
        .halt(halt)
    );
    
    // Data bus driver - controlled by testbench based on address and mem_read
    assign data_bus = (mem_read && addr_bus < 16'h0100) ? rom_array[addr_bus] :
                     (mem_read && addr_bus >= 16'h0100) ? ram_array[addr_bus] :
                     8'hZZ;
    
    // RAM write (reference only - actual RAM is in cpu_top)
    always @(posedge clk) begin
        if (mem_write && addr_bus >= 16'h0100) begin
            ram_array[addr_bus] <= acc_out;
        end
    end
    
    // Clock generation
    always #5 clk = ~clk;
    
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
            if (addr_bus < 16'h0100) begin
                $write("  ROM[0x%04h] = 0x%02h", addr_bus, rom_array[addr_bus]);
            end else begin
                $write("  RAM[0x%04h] = 0x%02h", addr_bus, ram_array[addr_bus]);
            end
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
        rom_array[16'h0000] = `OPCODE_LDA_IMM;
        rom_array[16'h0001] = 8'h55;
        rom_array[16'h0002] = `OPCODE_LDX_IMM;
        rom_array[16'h0003] = 8'hAA;
        rom_array[16'h0004] = `OPCODE_LDY_IMM;
        rom_array[16'h0005] = 8'h33;
        rom_array[16'h0006] = `OPCODE_ADD_IMM;
        rom_array[16'h0007] = 8'h0A;
        rom_array[16'h0008] = `OPCODE_SUB_IMM;
        rom_array[16'h0009] = 8'h05;
        rom_array[16'h000A] = `OPCODE_AND_IMM;
        rom_array[16'h000B] = 8'hFF;
        rom_array[16'h000C] = `OPCODE_OR_IMM;
        rom_array[16'h000D] = 8'h0F;
        rom_array[16'h000E] = `OPCODE_XOR_IMM;
        rom_array[16'h000F] = 8'hFF;
        rom_array[16'h0010] = `OPCODE_NOT;
        rom_array[16'h0011] = `OPCODE_INC;
        rom_array[16'h0012] = `OPCODE_DEC;
        rom_array[16'h0013] = `OPCODE_NOP;
        for (i = 16'h0014; i < 16'h0100; i = i + 1) rom_array[i] = `OPCODE_NOP;
        
        for (i = 16'h0100; i < 16'hFFFF; i = i + 1) ram_array[i] = 8'h00;
        
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
        
        repeat (30) begin
            @(posedge clk);
            #1;
            print_state("EXECUTE");
        end
        
        // Summary
        for (i = 0; i < 80; i = i + 1) $write("=");
        $write("\n");
        $write("SIMULATION COMPLETE\n");
        $write("Total clock cycles: %0d\n", clock_cycles);
        $write("Final ACC: 0x%02h  (Expected: 0x5F = 95)\n", acc_out);
        $write("Final X:   0x%02h  (Expected: 0xAA = 170)\n", x_out);
        $write("Final Y:   0x%02h  (Expected: 0x33 = 51)\n", y_out);
        for (i = 0; i < 80; i = i + 1) $write("=");
        $write("\n\n");
        
        #100;
        $finish;
    end
    
    initial begin
        #100000;
        $write("\nTIMEOUT - Simulation took too long\n");
        $finish;
    end
    
endmodule
