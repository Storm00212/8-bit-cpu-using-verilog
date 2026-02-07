// ============================================================================
// Minimal ROM Test
// ============================================================================

`timescale 1ns/1ps

module rom_test;
    reg [15:0] addr;
    wire [7:0] data_out;
    
    reg [7:0] memory [0:65535];
    
    // ROM instance
    rom uut (.addr(addr), .data_out(data_out));
    
    // Initialize ROM
    initial begin
        memory[0] = 8'h01;
        memory[1] = 8'h55;
        memory[2] = 8'hAA;
    end
    
    // Connect ROM output to memory
    assign uut.memory[0] = memory[0];  // This won't work - memory is internal
    
    // Direct assignment from memory to ROM output
    // This is what we want but can't do directly
    
    initial begin
        addr = 0;
        #10;
        $display("addr=%h, data_out=%h", addr, data_out);
        addr = 1;
        #10;
        $display("addr=%h, data_out=%h", addr, data_out);
        $finish;
    end
endmodule
