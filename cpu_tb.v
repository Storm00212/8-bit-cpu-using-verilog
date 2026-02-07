// ============================================================================
// CPU Testbench - Simple Version with VCD Waveform Output
// ============================================================================
// 
// This testbench verifies basic CPU functionality and generates a VCD
// waveform file that can be viewed in GTKWave.
// 
// To view waveforms:
// 1. Compile: iverilog -o cpu_sim cpu_tb.v cpu_top.v alu.v control_unit.v register_file.v ram.v rom.v
// 2. Run: vvp cpu_sim
// 3. View: gtkwave cpu_dump.vcd
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
    
    // Clock generation
    always #5 clk = ~clk;
    
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
    
    // Data bus driver
    assign data_bus = (mem_read) ? mem_data_out : 8'hZZ;
    
    // Test counters
    integer passed = 0;
    integer failed = 0;
    
    // =========================================================================
    // VCD Dump for Waveform Viewing
    // =========================================================================
    // This section creates a VCD (Value Change Dump) file that can be
    // opened in GTKWave to view the simulation waveforms.
    //
    // Usage:
    //   1. Run the simulation: vvp cpu_sim
    //   2. Open GTKWave: gtkwave cpu_dump.vcd
    //   3. Expand the module hierarchy in the left panel
    //   4. Drag signals to the waveform panel
    
    initial begin
        // Create VCD dump file
        $dumpfile("cpu_dump.vcd");
        
        // Dump all variables in this module and sub-modules
        $dumpvars(0, cpu_tb);
        
        // Alternatively, dump specific signals:
        // $dumpvars(0, clk);
        // $dumpvars(0, reset);
        // $dumpvars(0, acc_out);
        // $dumpvars(0, pc_out);
        // $dumpvars(0, data_bus);
        // $dumpvars(0, addr_bus);
    end
    
    // =========================================================================
    // Main Test Sequence
    // =========================================================================
    
    initial begin
        clk = 0;
        reset = 0;
        
        $display("========================================");
        $display("8-bit CPU Testbench with VCD Output");
        $display("========================================");
        $display("To view waveforms, run:");
        $display("  1. iverilog -o cpu_sim cpu_tb.v cpu_top.v alu.v control_unit.v register_file.v ram.v rom.v");
        $display("  2. vvp cpu_sim");
        $display("  3. gtkwave cpu_dump.vcd");
        $display("========================================");
        $display("");
        
        // Wait for initialization
        #100;
        
        // ------------------------------------------------
        // Test 1: LDA Immediate
        // ------------------------------------------------
        $display("Test 1: LDA #immediate");
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h55;
        rom[16'h0002] = 8'h00;  // NOP to stop
        
        reset = 1;
        @(posedge clk) #1;
        reset = 0;
        
        @(posedge clk) #10;  // Execute LDA
        @(posedge clk) #10;  // Execute operand fetch
        
        if (acc_out == 8'h55) begin
            $display("  PASS: LDA #0x55");
            passed = passed + 1;
        end else begin
            $display("  FAIL: LDA #0x55 - Expected 0x55, Got 0x%02h", acc_out);
            failed = failed + 1;
        end
        
        // ------------------------------------------------
        // Test 2: ADD Immediate
        // ------------------------------------------------
        $display("Test 2: ADD #immediate (10 + 5 = 15)");
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h0A;
        rom[16'h0002] = `OPCODE_ADD_IMM;
        rom[16'h0003] = 8'h05;
        rom[16'h0004] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'h0F) begin
            $display("  PASS: ADD (0x0A + 0x05 = 0x0F)");
            passed = passed + 1;
        end else begin
            $display("  FAIL: ADD - Expected 0x0F, Got 0x%02h", acc_out);
            failed = failed + 1;
        end
        
        // ------------------------------------------------
        // Test 3: SUB Immediate
        // ------------------------------------------------
        $display("Test 3: SUB #immediate (10 - 3 = 7)");
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h0A;
        rom[16'h0002] = `OPCODE_SUB_IMM;
        rom[16'h0003] = 8'h03;
        rom[16'h0004] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'h07) begin
            $display("  PASS: SUB (0x0A - 0x03 = 0x07)");
            passed = passed + 1;
        end else begin
            $display("  FAIL: SUB - Expected 0x07, Got 0x%02h", acc_out);
            failed = failed + 1;
        end
        
        // ------------------------------------------------
        // Test 4: AND Immediate
        // ------------------------------------------------
        $display("Test 4: AND #immediate (FF & 0F = 0F)");
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'hFF;
        rom[16'h0002] = `OPCODE_AND_IMM;
        rom[16'h0003] = 8'h0F;
        rom[16'h0004] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'h0F) begin
            $display("  PASS: AND (0xFF & 0x0F = 0x0F)");
            passed = passed + 1;
        end else begin
            $display("  FAIL: AND - Expected 0x0F, Got 0x%02h", acc_out);
            failed = failed + 1;
        end
        
        // ------------------------------------------------
        // Test 5: OR Immediate
        // ------------------------------------------------
        $display("Test 5: OR #immediate (0F | F0 = FF)");
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h0F;
        rom[16'h0002] = `OPCODE_OR_IMM;
        rom[16'h0003] = 8'hF0;
        rom[16'h0004] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'hFF) begin
            $display("  PASS: OR (0x0F | 0xF0 = 0xFF)");
            passed = passed + 1;
        end else begin
            $display("  FAIL: OR - Expected 0xFF, Got 0x%02h", acc_out);
            failed = failed + 1;
        end
        
        // ------------------------------------------------
        // Test 6: XOR Immediate
        // ------------------------------------------------
        $display("Test 6: XOR #immediate (FF ^ FF = 00)");
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'hFF;
        rom[16'h0002] = `OPCODE_XOR_IMM;
        rom[16'h0003] = 8'hFF;
        rom[16'h0004] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'h00) begin
            $display("  PASS: XOR (0xFF ^ 0xFF = 0x00)");
            passed = passed + 1;
        end else begin
            $display("  FAIL: XOR - Expected 0x00, Got 0x%02h", acc_out);
            failed = failed + 1;
        end
        
        // ------------------------------------------------
        // Test 7: NOT
        // ------------------------------------------------
        $display("Test 7: NOT (~00 = FF)");
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h00;
        rom[16'h0002] = `OPCODE_NOT;
        rom[16'h0003] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'hFF) begin
            $display("  PASS: NOT (~0x00 = 0xFF)");
            passed = passed + 1;
        end else begin
            $display("  FAIL: NOT - Expected 0xFF, Got 0x%02h", acc_out);
            failed = failed + 1;
        end
        
        // ------------------------------------------------
        // Test 8: INC
        // ------------------------------------------------
        $display("Test 8: INC (7F + 1 = 80)");
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h7F;
        rom[16'h0002] = `OPCODE_INC;
        rom[16'h0003] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'h80) begin
            $display("  PASS: INC (0x7F + 1 = 0x80)");
            passed = passed + 1;
        end else begin
            $display("  FAIL: INC - Expected 0x80, Got 0x%02h", acc_out);
            failed = failed + 1;
        end
        
        // ------------------------------------------------
        // Test 9: DEC
        // ------------------------------------------------
        $display("Test 9: DEC (80 - 1 = 7F)");
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h80;
        rom[16'h0002] = `OPCODE_DEC;
        rom[16'h0003] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'h7F) begin
            $display("  PASS: DEC (0x80 - 1 = 0x7F)");
            passed = passed + 1;
        end else begin
            $display("  FAIL: DEC - Expected 0x7F, Got 0x%02h", acc_out);
            failed = failed + 1;
        end
        
        // ------------------------------------------------
        // Test 10: LDX Immediate
        // ------------------------------------------------
        $display("Test 10: LDX #immediate");
        rom[16'h0000] = `OPCODE_LDX_IMM;
        rom[16'h0001] = 8'hAB;
        rom[16'h0002] = 8'h00;
        
        @(posedge clk) #20;
        
        if (x_out == 8'hAB) begin
            $display("  PASS: LDX #0xAB");
            passed = passed + 1;
        end else begin
            $display("  FAIL: LDX - Expected 0xAB, Got 0x%02h", x_out);
            failed = failed + 1;
        end
        
        // ------------------------------------------------
        // Test 11: LDY Immediate
        // ------------------------------------------------
        $display("Test 11: LDY #immediate");
        rom[16'h0000] = `OPCODE_LDY_IMM;
        rom[16'h0001] = 8'hCD;
        rom[16'h0002] = 8'h00;
        
        @(posedge clk) #20;
        
        if (y_out == 8'hCD) begin
            $display("  PASS: LDY #0xCD");
            passed = passed + 1;
        end else begin
            $display("  FAIL: LDY - Expected 0xCD, Got 0x%02h", y_out);
            failed = failed + 1;
        end
        
        // ------------------------------------------------
        // Test Summary
        // ------------------------------------------------
        $display("");
        $display("========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);
        $display("========================================");
        $display("Waveform saved to: cpu_dump.vcd");
        $display("========================================");
        
        #100;
        $finish;
    end
    
    // =========================================================================
    // Timeout Protection
    // =========================================================================
    // Prevent simulation from running indefinitely.
    // Force finish after 5000ns if tests hang.
    
    initial begin
        #5000;
        $display("TIMEOUT: Simulation exceeded 5000ns");
        $display("Waveform data up to this point saved in cpu_dump.vcd");
        $finish;
    end
    
endmodule
