// ============================================================================
// CPU Verification Testbench
// ============================================================================
// 
// This tests basic functionality without relying on the control unit FSM
// ============================================================================

`timescale 1ns/1ps

`include "instructions.vh"

module cpu_tb;
    
    // Testbench signals
    reg clk;
    reg reset;
    
    // Register file signals
    wire [7:0] acc_out, x_out, y_out, sp_out, ir_out, flags_out;
    wire [15:0] pc_out, addr_bus;
    wire acc_write, x_write, y_write, pc_write, pc_inc, pc_load;
    wire sp_write, ir_write, flags_write;
    wire [15:0] pc_direct;
    
    // ALU signals
    wire [7:0] alu_result, alu_flags;
    wire alu_done;
    wire [3:0] alu_operation;
    wire [7:0] data_bus;
    
    // Control signals
    wire done;
    
    // Memory
    reg [7:0] rom [0:255];
    reg [7:0] mem_data_out;
    
    always @(addr_bus) begin
        if (addr_bus < 16'h0100) begin
            mem_data_out = rom[addr_bus];
        end
    end
    
    assign data_bus = mem_data_out;
    
    always #5 clk = ~clk;
    
    // Instantiate register file
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
        .acc_out(acc_out),
        .x_out(x_out),
        .y_out(y_out),
        .pc_out(pc_out),
        .sp_out(sp_out),
        .ir_out(ir_out),
        .flags_out(flags_out),
        .addr_bus(addr_bus)
    );
    
    // Instantiate ALU
    alu alu_unit (
        .clk(clk),
        .reset(reset),
        .a(acc_out),
        .b(data_bus),
        .operation(alu_operation),
        .result(alu_result),
        .flags(alu_flags),
        .done(alu_done)
    );
    
    integer i;
    
    initial begin
        clk = 0;
        reset = 0;
        
        $write("\n========================================\n");
        $write("   CPU COMPONENT TESTBENCH\n");
        $write("========================================\n\n");
        $fflush;
        
        // Test 1: Reset
        $write("Test 1: RESET\n");
        $fflush;
        reset = 1;
        @(posedge clk);
        #1;
        $write("  After reset:\n");
        $write("    ACC = 0x%02h (expected 0x00)\n", acc_out);
        $write("    PC  = 0x%04h (expected 0x0000)\n", pc_out);
        $write("    X   = 0x%02h (expected 0x00)\n", x_out);
        $write("    Y   = 0x%02h (expected 0x00)\n", y_out);
        $write("    FLAGS = 0x%02h (expected 0x00)\n", flags_out);
        $fflush;
        reset = 0;
        @(posedge clk);
        #1;
        
        // Test 2: Load accumulator immediate
        $write("\nTest 2: LOAD ACCUMULATOR\n");
        $fflush;
        #100;
        $write("  ACC = 0x%02h\n", acc_out);
        $write("  PC  = 0x%04h\n", pc_out);
        $fflush;
        
        // Test 3: ALU ADD
        $write("\nTest 3: ALU ADD (5 + 3 = 8)\n");
        $fflush;
        #100;
        $write("  ACC = 0x%02h (decimal: %0d)\n", acc_out, acc_out);
        $write("  FLAGS = 0x%02h\n", flags_out);
        $write("    Z (Zero) = %b\n", flags_out[1]);
        $write("    N (Neg)  = %b\n", flags_out[2]);
        $write("    C (Carry)= %b\n", flags_out[0]);
        $fflush;
        
        $write("\n========================================\n");
        $write("   TESTS COMPLETE\n");
        $write("========================================\n\n");
        $fflush;
        
        #1000;
        $finish;
    end
    
    // Timeout
    initial begin
        #5000;
        $write("\nTIMEOUT\n");
        $fflush;
        $finish;
    end
    
endmodule
