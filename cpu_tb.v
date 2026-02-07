// ============================================================================
// CPU Testbench - Simple Monitor Version
// ============================================================================
// 
// Real-time terminal output showing CPU execution cycle by cycle
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
    
    assign data_bus = (mem_read) ? mem_data_out : 8'hZZ;
    
    // Print immediately without buffering
    integer i;
    
    initial begin
        clk = 0;
        reset = 0;
        
        // Print separator
        $write("\n");
        for (i = 0; i < 80; i = i + 1) $write("=");
        $write("\n");
        $write("                    8-BIT CPU SIMULATION - REAL-TIME MONITOR\n");
        for (i = 0; i < 80; i = i + 1) $write("=");
        $write("\n\n");
        $fflush;
        
        // Load simple program: LDA #55, ADD #0A, NOP
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h55;
        rom[16'h0002] = `OPCODE_ADD_IMM;
        rom[16'h0003] = 8'h0A;
        rom[16'h0004] = `OPCODE_NOP;
        
        $write("Program loaded:\n");
        $write("  0x0000: LDA #0x55\n");
        $write("  0x0002: ADD #0x0A\n");
        $write("  0x0004: NOP\n\n");
        $fflush;
        
        // Reset
        $write("Applying RESET...\n");
        $fflush;
        reset = 1;
        #10;
        reset = 0;
        #10;
        
        $write("\n");
        for (i = 0; i < 80; i = i + 1) $write("-");
        $write("\n");
        $write("EXECUTING INSTRUCTIONS\n");
        for (i = 0; i < 80; i = i + 1) $write("-");
        $write("\n\n");
        $fflush;
        
        // Execute 10 clock cycles
        repeat (10) begin
            @(posedge clk);
            #2;
            
            // Print state immediately
            $write("CLK+: PC=0x%04h ACC=0x%02h X=0x%02h Y=0x%02h FLAGS=0x%02h ADDR=0x%04h DATA=0x%02h\n",
                   pc_out, acc_out, x_out, y_out, flags_out, addr_bus, data_bus);
            $fflush;
        end
        
        $write("\n");
        for (i = 0; i < 80; i = i + 1) $write("=");
        $write("\n");
        $write("SIMULATION COMPLETE\n");
        for (i = 0; i < 80; i = i + 1) $write("=");
        $write("\n\n");
        $fflush;
        
        #100;
        $finish;
    end
    
    // Timeout
    initial begin
        #5000;
        $write("\nTIMEOUT - Simulation took too long\n");
        $fflush;
        $finish;
    end
    
endmodule
