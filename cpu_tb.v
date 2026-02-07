// ============================================================================
// CPU Testbench - Simple Version
// ============================================================================
// 
// This testbench verifies basic CPU functionality by testing individual
// instructions in sequence without infinite loops.
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
    
    // Clock
    always #5 clk = ~clk;
    
    // CPU
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
    
    integer passed = 0;
    integer failed = 0;
    
    task test_op;
        input [7:0] opcode;
        input [7:0] operand;
        input [7:0] expected;
        input [80:0] name;
        begin
            rom[16'h0000] = opcode;
            rom[16'h0001] = operand;
            rom[16'h0002] = 8'h00;  // NOP to stop
            
            reset = 1;
            @(posedge clk) #1;
            reset = 0;
            
            @(posedge clk) #10;  // Execute opcode
            @(posedge clk) #10;  // Execute operand fetch
            
            if (acc_out == expected) begin
                $display("PASS: %s", name);
                passed = passed + 1;
            end else begin
                $display("FAIL: %s - Expected 0x%02h, Got 0x%02h", name, expected, acc_out);
                failed = failed + 1;
            end
        end
    endtask
    
    initial begin
        clk = 0;
        reset = 0;
        
        $display("========================================");
        $display("8-bit CPU Testbench");
        $display("========================================");
        
        #100;
        
        // Test LDA immediate
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h55;
        rom[16'h0002] = 8'h00;
        
        reset = 1;
        @(posedge clk) #1;
        reset = 0;
        @(posedge clk) #20;
        
        if (acc_out == 8'h55) begin
            $display("PASS: LDA #immediate");
            passed = passed + 1;
        end else begin
            $display("FAIL: LDA #immediate - Expected 55, Got %h", acc_out);
            failed = failed + 1;
        end
        
        // Test ADD immediate
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h0A;
        rom[16'h0002] = `OPCODE_ADD_IMM;
        rom[16'h0003] = 8'h05;
        rom[16'h0004] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'h0F) begin
            $display("PASS: ADD immediate (10 + 5 = 15)");
            passed = passed + 1;
        end else begin
            $display("FAIL: ADD immediate - Expected 0F, Got %h", acc_out);
            failed = failed + 1;
        end
        
        // Test SUB immediate
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h0A;
        rom[16'h0002] = `OPCODE_SUB_IMM;
        rom[16'h0003] = 8'h03;
        rom[16'h0004] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'h07) begin
            $display("PASS: SUB immediate (10 - 3 = 7)");
            passed = passed + 1;
        end else begin
            $display("FAIL: SUB immediate - Expected 07, Got %h", acc_out);
            failed = failed + 1;
        end
        
        // Test AND immediate
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'hFF;
        rom[16'h0002] = `OPCODE_AND_IMM;
        rom[16'h0003] = 8'h0F;
        rom[16'h0004] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'h0F) begin
            $display("PASS: AND immediate (FF & 0F = 0F)");
            passed = passed + 1;
        end else begin
            $display("FAIL: AND immediate - Expected 0F, Got %h", acc_out);
            failed = failed + 1;
        end
        
        // Test OR immediate
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h0F;
        rom[16'h0002] = `OPCODE_OR_IMM;
        rom[16'h0003] = 8'hF0;
        rom[16'h0004] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'hFF) begin
            $display("PASS: OR immediate (0F | F0 = FF)");
            passed = passed + 1;
        end else begin
            $display("FAIL: OR immediate - Expected FF, Got %h", acc_out);
            failed = failed + 1;
        end
        
        // Test XOR immediate
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'hFF;
        rom[16'h0002] = `OPCODE_XOR_IMM;
        rom[16'h0003] = 8'hFF;
        rom[16'h0004] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'h00) begin
            $display("PASS: XOR immediate (FF ^ FF = 00)");
            passed = passed + 1;
        end else begin
            $display("FAIL: XOR immediate - Expected 00, Got %h", acc_out);
            failed = failed + 1;
        end
        
        // Test NOT
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h00;
        rom[16'h0002] = `OPCODE_NOT;
        rom[16'h0003] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'hFF) begin
            $display("PASS: NOT (~00 = FF)");
            passed = passed + 1;
        end else begin
            $display("FAIL: NOT - Expected FF, Got %h", acc_out);
            failed = failed + 1;
        end
        
        // Test INC
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h7F;
        rom[16'h0002] = `OPCODE_INC;
        rom[16'h0003] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'h80) begin
            $display("PASS: INC (7F + 1 = 80)");
            passed = passed + 1;
        end else begin
            $display("FAIL: INC - Expected 80, Got %h", acc_out);
            failed = failed + 1;
        end
        
        // Test DEC
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h80;
        rom[16'h0002] = `OPCODE_DEC;
        rom[16'h0003] = 8'h00;
        
        @(posedge clk) #20;
        
        if (acc_out == 8'h7F) begin
            $display("PASS: DEC (80 - 1 = 7F)");
            passed = passed + 1;
        end else begin
            $display("FAIL: DEC - Expected 7F, Got %h", acc_out);
            failed = failed + 1;
        end
        
        // Test LDX
        rom[16'h0000] = `OPCODE_LDX_IMM;
        rom[16'h0001] = 8'hAB;
        rom[16'h0002] = 8'h00;
        
        @(posedge clk) #20;
        
        if (x_out == 8'hAB) begin
            $display("PASS: LDX #immediate");
            passed = passed + 1;
        end else begin
    endtask
    
    // Test shift operations
    task test_shift;
        input [7:0] value;
        input [1:0] operation;   // 0=SHL, 1=SHR, 2=ROL, 3=ROR
        input [7:0] expected;
        begin
            test_count = test_count + 1;
            
            @(posedge clk);
            #10;
            
            if (acc_out == expected) begin
                $display("PASS: Shift test %0d", test_count);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Shift test %0d - Expected=%h, Got=%h",
                         test_count, expected, acc_out);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    // =========================================================================
    // Register Change Monitor
    // =========================================================================
    // Monitor and display changes to CPU registers during simulation.
    // This helps track CPU state during test execution.
    
    always @(acc_out or x_out or y_out or pc_out) begin
        $display("ACC=%h, X=%h, Y=%h, PC=%h, FLAGS=%h",
                 acc_out, x_out, y_out, pc_out, flags_out);
    end
    
    // =========================================================================
    // Main Test Sequence
    // =========================================================================
    
    initial begin
        // Initialize signals
        clk = 1'b0;
        reset = 1'b0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        $display("========================================");
        $display("8-bit CPU Testbench");
        $display("========================================");
        $display("");
        
        // Wait for initialization
        #100;
        
        // ========================================
        // Test 1: Reset
        // ========================================
        test_reset;
        
        // ========================================
        // Test 2: Load Immediate
        // ========================================
        test_count = test_count + 1;
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h55;
        @(posedge clk) #10;
        if (acc_out == 8'h55) begin
            $display("PASS: Load Immediate test");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Load Immediate - Expected=55, Got=%h", acc_out);
            fail_count = fail_count + 1;
        end
        
        // ========================================
        // Test 3: Addition
        // ========================================
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h0A;  // Load 10
        rom[16'h0002] = `OPCODE_ADD_IMM;
        rom[16'h0003] = 8'h05;  // Add 5
        @(posedge clk) #10;
        if (acc_out == 8'h0F) begin
            $display("PASS: Addition test (10 + 5 = 15)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Addition test - Expected=0F, Got=%h", acc_out);
            fail_count = fail_count + 1;
        end
        
        // ========================================
        // Test 4: Subtraction
        // ========================================
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h0A;  // Load 10
        rom[16'h0002] = `OPCODE_SUB_IMM;
        rom[16'h0003] = 8'h03;  // Subtract 3
        @(posedge clk) #10;
        if (acc_out == 8'h07) begin
            $display("PASS: Subtraction test (10 - 3 = 7)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Subtraction test - Expected=07, Got=%h", acc_out);
            fail_count = fail_count + 1;
        end
        
        // ========================================
        // Test 5: Logical AND
        // ========================================
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'hFF;  // Load 255
        rom[16'h0002] = `OPCODE_AND_IMM;
        rom[16'h0003] = 8'h0F;  // AND with 15
        @(posedge clk) #10;
        if (acc_out == 8'h0F) begin
            $display("PASS: AND test (FF & 0F = 0F)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: AND test - Expected=0F, Got=%h", acc_out);
            fail_count = fail_count + 1;
        end
        
        // ========================================
        // Test 6: Logical OR
        // ========================================
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h0F;  // Load 15
        rom[16'h0002] = `OPCODE_OR_IMM;
        rom[16'h0003] = 8'hF0;  // OR with 240
        @(posedge clk) #10;
        if (acc_out == 8'hFF) begin
            $display("PASS: OR test (0F | F0 = FF)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: OR test - Expected=FF, Got=%h", acc_out);
            fail_count = fail_count + 1;
        end
        
        // ========================================
        // Test 7: Logical XOR
        // ========================================
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'hFF;  // Load 255
        rom[16'h0002] = `OPCODE_XOR_IMM;
        rom[16'h0003] = 8'hFF;  // XOR with 255
        @(posedge clk) #10;
        if (acc_out == 8'h00) begin
            $display("PASS: XOR test (FF ^ FF = 00)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: XOR test - Expected=00, Got=%h", acc_out);
            fail_count = fail_count + 1;
        end
        
        // ========================================
        // Test 8: NOT
        // ========================================
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h00;  // Load 0
        rom[16'h0002] = `OPCODE_NOT;
        @(posedge clk) #10;
        if (acc_out == 8'hFF) begin
            $display("PASS: NOT test (~00 = FF)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: NOT test - Expected=FF, Got=%h", acc_out);
            fail_count = fail_count + 1;
        end
        
        // ========================================
        // Test 9: Increment
        // ========================================
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h7F;  // Load 127
        rom[16'h0002] = `OPCODE_INC;
        @(posedge clk) #10;
        if (acc_out == 8'h80) begin
            $display("PASS: Increment test (7F + 1 = 80)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Increment test - Expected=80, Got=%h", acc_out);
            fail_count = fail_count + 1;
        end
        
        // ========================================
        // Test 10: Decrement
        // ========================================
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h80;  // Load 128
        rom[16'h0002] = `OPCODE_DEC;
        @(posedge clk) #10;
        if (acc_out == 8'h7F) begin
            $display("PASS: Decrement test (80 - 1 = 7F)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Decrement test - Expected=7F, Got=%h", acc_out);
            fail_count = fail_count + 1;
        end
        
        // ========================================
        // Test 11: X Register Load
        // ========================================
        rom[16'h0000] = `OPCODE_LDX_IMM;
        rom[16'h0001] = 8'hAB;
        @(posedge clk) #10;
        if (x_out == 8'hAB) begin
            $display("PASS: X Register Load test");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: X Register Load - Expected=AB, Got=%h", x_out);
            fail_count = fail_count + 1;
        end
        
        // ========================================
        // Test 12: Y Register Load
        // ========================================
        rom[16'h0000] = `OPCODE_LDY_IMM;
        rom[16'h0001] = 8'hCD;
        @(posedge clk) #10;
        if (y_out == 8'hCD) begin
            $display("PASS: Y Register Load test");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Y Register Load - Expected=CD, Got=%h", y_out);
            fail_count = fail_count + 1;
        end
        
        // Wait for completion
        #1000;
        
        // ========================================
        // Test Summary
        // ========================================
        $display("");
        $display("========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("Pass rate: %0d%%", (pass_count * 100) / test_count);
        $display("========================================");
        
        $finish;
    end
    
    // =========================================================================
    // Timeout Protection
    // =========================================================================
    // Prevent simulation from running indefinitely.
    // Force finish after 1000ns.
    
    initial begin
        #1000;
        $display("TIMEOUT: Simulation exceeded 1000ns");
        $finish;
    end
    
endmodule
