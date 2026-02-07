// ============================================================
// CPU Testbench
// Tests all operations of the 8-bit CPU
// ============================================================

`timescale 1ns/1ps

`include "instructions.vh"

module cpu_tb;
    
    // Testbench signals
    reg         clk;
    reg         reset;
    wire [7:0]  data_bus;
    wire [15:0] addr_bus;
    wire        mem_read;
    wire        mem_write;
    wire [7:0]  acc_out;
    wire [15:0] pc_out;
    wire [7:0]  flags_out;
    wire [7:0]  x_out;
    wire [7:0]  y_out;
    wire        halt;
    
    // Simulation counters
    integer     test_count;
    integer     pass_count;
    integer     fail_count;
    
    // Clock generation
    always #5 clk = ~clk;  // 100MHz clock
    
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
    
    // RAM instance for simulation
    reg [7:0] ram [0:65535];
    reg [7:0] rom [0:65535];
    reg [7:0] mem_data_out;
    
    // Memory model
    always @(addr_bus) begin
        if (addr_bus < 16'h0100) begin
            mem_data_out = rom[addr_bus];
        end else begin
            mem_data_out = ram[addr_bus];
        end
    end
    
    // Write to memory
    always @(posedge clk) begin
        if (mem_write) begin
            ram[addr_bus] <= acc_out;
        end
    end
    
    // Initialize ROM with test program
    initial begin
        // Initialize ROM
        rom[16'h0000] = `OPCODE_LDA_IMM;  // LDA #10
        rom[16'h0001] = 8'h0A;            // Immediate value 10
        rom[16'h0002] = `OPCODE_LDX_IMM;  // LDX #5
        rom[16'h0003] = 8'h05;            // Immediate value 5
        rom[16'h0004] = `OPCODE_ADD_IMM;  // ADD #3
        rom[16'h0005] = 8'h03;            // Immediate value 3
        rom[16'h0006] = `OPCODE_SUB_IMM;  // SUB #2
        rom[16'h0007] = 8'h02;            // Immediate value 2
        rom[16'h0008] = `OPCODE_INC;     // INC
        rom[16'h0009] = `OPCODE_DEC;     // DEC
        rom[16'h000A] = `OPCODE_MUL;     // MUL (ACC * X)
        rom[16'h000B] = `OPCODE_NOP;     // NOP
        rom[16'h000C] = `OPCODE_HALT;    // HALT
        
        // Fill rest of ROM with NOP
        for (integer i = 16'h000D; i < 16'h0100; i = i + 1) begin
            rom[i] = `OPCODE_NOP;
        end
    end
    
    // Add HALT opcode if not defined
    initial begin
        if (`OPCODE_HALT == `OPCODE_NOP) begin
            $display("Note: Adding HALT opcode");
        end
    end
    
    // Test tasks
    task test_reset;
        begin
            test_count = test_count + 1;
            reset = 1'b1;
            @(posedge clk) #1;
            reset = 1'b0;
            @(posedge clk) #10;
            if (acc_out == 8'h00 && pc_out == 16'h0000) begin
                $display("PASS: Reset test %0d", test_count);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Reset test %0d - ACC=%h, PC=%h", 
                         test_count, acc_out, pc_out);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    task test_load_store;
        input [7:0] test_value;
        input [7:0] mem_addr;
        begin
            test_count = test_count + 1;
            
            // Write value to RAM
            ram[mem_addr] = test_value;
            
            // Load from RAM and verify
            @(posedge clk);
            #10;
            
            if (acc_out == test_value) begin
                $display("PASS: Load/Store test %0d - Value=%h", 
                         test_count, test_value);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Load/Store test %0d - Expected=%h, Got=%h", 
                         test_count, test_value, acc_out);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    task test_addition;
        input [7:0] a, b;
        input [7:8] expected_carry;
        input [7:0] expected_result;
        begin
            test_count = test_count + 1;
            
            // Perform addition
            @(posedge clk);
            #10;
            
            if (acc_out == expected_result) begin
                $display("PASS: Addition test %0d - %0d + %0d = %0d", 
                         test_count, a, b, expected_result);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Addition test %0d - %0d + %0d = %0d, Expected=%h",
                         test_count, a, b, expected_result, acc_out);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    task test_subtraction;
        input [7:0] a, b;
        input [7:0] expected_result;
        begin
            test_count = test_count + 1;
            
            // Perform subtraction
            @(posedge clk);
            #10;
            
            if (acc_out == expected_result) begin
                $display("PASS: Subtraction test %0d - %0d - %0d = %0d", 
                         test_count, a, b, expected_result);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Subtraction test %0d - Expected=%h, Got=%h",
                         test_count, expected_result, acc_out);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    task test_logical;
        input [7:0] a, b;
        input [2:0] operation;  // 0=AND, 1=OR, 2=XOR
        input [7:0] expected;
        begin
            test_count = test_count + 1;
            
            @(posedge clk);
            #10;
            
            if (acc_out == expected) begin
                $display("PASS: Logical test %0d", test_count);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Logical test %0d - Expected=%h, Got=%h",
                         test_count, expected, acc_out);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    task test_shift;
        input [7:0] value;
        input [1:0] operation;  // 0=SHL, 1=SHR, 2=ROL, 3=ROR
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
    
    // Monitor register changes
    always @(acc_out or x_out or y_out or pc_out) begin
        $display("ACC=%h, X=%h, Y=%h, PC=%h, FLAGS=%h",
                 acc_out, x_out, y_out, pc_out, flags_out);
    end
    
    // Main test sequence
    initial begin
        // Initialize
        clk = 1'b0;
        reset = 1'b0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        $display("===========================================");
        $display("8-bit CPU Testbench");
        $display("===========================================");
        
        // Wait for initialization
        #100;
        
        // Test 1: Reset
        test_reset;
        
        // Test 2: Load Immediate
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
        
        // Test 3: Addition
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
        
        // Test 4: Subtraction
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
        
        // Test 5: Logical AND
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
        
        // Test 6: Logical OR
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
        
        // Test 7: Logical XOR
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
        
        // Test 8: NOT
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h00;  // Load 0
        rom[16'h0002] = `OPCODE_NOT;  // NOT
        @(posedge clk) #10;
        if (acc_out == 8'hFF) begin
            $display("PASS: NOT test (~00 = FF)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: NOT test - Expected=FF, Got=%h", acc_out);
            fail_count = fail_count + 1;
        end
        
        // Test 9: Increment
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h7F;  // Load 127
        rom[16'h0002] = `OPCODE_INC;  // INC
        @(posedge clk) #10;
        if (acc_out == 8'h80) begin
            $display("PASS: Increment test (7F + 1 = 80)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Increment test - Expected=80, Got=%h", acc_out);
            fail_count = fail_count + 1;
        end
        
        // Test 10: Decrement
        rom[16'h0000] = `OPCODE_LDA_IMM;
        rom[16'h0001] = 8'h80;  // Load 128
        rom[16'h0002] = `OPCODE_DEC;  // DEC
        @(posedge clk) #10;
        if (acc_out == 8'h7F) begin
            $display("PASS: Decrement test (80 - 1 = 7F)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Decrement test - Expected=7F, Got=%h", acc_out);
            fail_count = fail_count + 1;
        end
        
        // Test 11: X Register Load
        rom[16'h0000] = `OPCODE_LDX_IMM;
        rom[16'h0001] = 8'hAB;  // Load X with AB
        @(posedge clk) #10;
        if (x_out == 8'hAB) begin
            $display("PASS: X Register Load test");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: X Register Load - Expected=AB, Got=%h", x_out);
            fail_count = fail_count + 1;
        end
        
        // Test 12: Y Register Load
        rom[16'h0000] = `OPCODE_LDY_IMM;
        rom[16'h0001] = 8'hCD;  // Load Y with CD
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
        
        // Display summary
        $display("===========================================");
        $display("Test Summary");
        $display("===========================================");
        $display("Total tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("Pass rate: %0d%%", (pass_count * 100) / test_count);
        $display("===========================================");
        
        $finish;
    end
    
    // Timeout
    initial begin
        #5000;
        $display("TIMEOUT: Simulation exceeded 5000ns");
        $finish;
    end
    
endmodule
