// ============================================================================
// CPU Testbench - Real-Time Monitoring Version
// ============================================================================
// 
// This testbench displays comprehensive real-time output showing:
// - Clock cycle count
// - Instruction fetch (opcode and operand)
// - Instruction decode and execute phases
// - Memory accesses (read/write)
// - Data bus and address bus values
// - All control signals
// - Register values (ACC, X, Y, PC, SP, IR, Flags)
// - ALU operations and results
// ============================================================================

`timescale 1ns/1ps

`include "instructions.vh"

module cpu_tb;
    
    // =========================================================================
    // CPU Interface Signals
    // =========================================================================
    
    reg clk;                          // System clock
    reg reset;                        // Reset signal
    
    wire [7:0] data_bus;            // 8-bit bidirectional data bus
    wire [15:0] addr_bus;           // 16-bit address bus
    wire mem_read;                   // Memory read enable
    wire mem_write;                  // Memory write enable
    wire [7:0] acc_out;             // Accumulator output
    wire [15:0] pc_out;             // Program counter output
    wire [7:0] flags_out;           // Flags register output
    wire [7:0] x_out;               // X register output
    wire [7:0] y_out;               // Y register output
    wire halt;                       // Halt signal
    
    // =========================================================================
    // Memory Model
    // =========================================================================
    
    reg [7:0] ram [0:65535];        // RAM array
    reg [7:0] rom [0:65535];        // ROM array
    reg [7:0] mem_data_out;         // Memory data output
    
    // Read from ROM or RAM based on address
    always @(addr_bus) begin
        if (addr_bus < 16'h0100) begin
            mem_data_out = rom[addr_bus];
        end else begin
            mem_data_out = ram[addr_bus];
        end
    end
    
    // Synchronous RAM write
    always @(posedge clk) begin
        if (mem_write) begin
            ram[addr_bus] <= acc_out;
            $display("[MEMORY WRITE] Address: 0x%04h, Data: 0x%02h", addr_bus, acc_out);
        end
    end
    
    // =========================================================================
    // Clock Generation
    // =========================================================================
    // 100MHz clock (10ns period)
    
    always #5 clk = ~clk;
    
    // =========================================================================
    // CPU Instance
    // =========================================================================
    
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
    
    // =========================================================================
    // Simulation Control
    // =========================================================================
    
    integer clock_count = 0;         // Clock cycle counter
    integer test_passed = 0;         // Passed tests counter
    integer test_failed = 0;         // Failed tests counter
    
    // =========================================================================
    // Real-Time Display Task
    // =========================================================================
    // Displays CPU state at each clock cycle
    
    task display_cpu_state;
        input [79:0] phase;
        begin
            clock_count = clock_count + 1;
            
            $display("");
            $display("================================================================================");
            $display("CLOCK CYCLE: %0d  |  PHASE: %s", clock_count, phase);
            $display("================================================================================");
            
            // Address and Data Buses
            $display("--- BUS SIGNALS ---");
            $display("  Address Bus: 0x%04h", addr_bus);
            $display("  Data Bus:    0x%02h", data_bus);
            $display("  Mem Read:    %b", mem_read);
            $display("  Mem Write:   %b", mem_write);
            
            // Program Counter and Instruction Register
            $display("--- PROGRAM FLOW ---");
            $display("  PC:  0x%04h", pc_out);
            $display("  Halt: %b", halt);
            
            // General Purpose Registers
            $display("--- REGISTERS ---");
            $display("  ACC: 0x%02h  (Decimal: %0d)", acc_out, acc_out);
            $display("  X:   0x%02h  (Decimal: %0d)", x_out, x_out);
            $display("  Y:   0x%02h  (Decimal: %0d)", y_out, y_out);
            
            // Flags Register
            $display("--- FLAGS ---");
            $display("  Flags:  0x%02h", flags_out);
            $display("    Bit 0 (C): Carry      = %b", flags_out[0]);
            $display("    Bit 1 (Z): Zero       = %b", flags_out[1]);
            $display("    Bit 2 (N): Negative  = %b", flags_out[2]);
            $display("    Bit 3 (V): Overflow  = %b", flags_out[3]);
            $display("    Bit 4 (I): IRQ Disable = %b", flags_out[4]);
            $display("    Bit 5 (D): Decimal   = %b", flags_out[5]);
            $display("    Bit 6 (B): Break     = %b", flags_out[6]);
            $display("    Bit 7 (X): Extended  = %b", flags_out[7]);
            
            // Memory Content at Current Address
            $display("--- MEMORY ---");
            $display("  ROM[0x%04h] = 0x%02h", addr_bus, rom[addr_bus]);
            if (addr_bus >= 16'h0100) begin
                $display("  RAM[0x%04h] = 0x%02h", addr_bus, ram[addr_bus]);
            end
            
            $display("");
        end
    endtask
    
    // =========================================================================
    // Initial ROM Programming
    // =========================================================================
    // Load test program into ROM
    
    task load_test_program;
        begin
            $display("");
            $display("================================================================================");
            $display("LOADING TEST PROGRAM INTO ROM");
            $display("================================================================================");
            
            // Test: LDA #0x55
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
            rom[16'h000F] = `OPCODE_INC;
            rom[16'h0010] = `OPCODE_DEC;
            rom[16'h0011] = 8'h00;  // Halt (NOP)
            
            // Fill rest with NOP
            for (integer i = 16'h0012; i < 16'h0100; i = i + 1) begin
                rom[i] = 8'h00;
            end
            
            $display("Test program loaded at 0x0000:");
            $display("  0x0000: LDA #0x55   ; Load accumulator with 0x55");
            $display("  0x0002: LDX #0xAA   ; Load X with 0xAA");
            $display("  0x0004: ADD #0x0A   ; Add 0x0A to ACC");
            $display("  0x0006: SUB #0x05   ; Subtract 0x05 from ACC");
            $display("  0x0008: AND #0xFF   ; AND with 0xFF");
            $display("  0x000A: OR  #0x0F   ; OR with 0x0F");
            $display("  0x000C: XOR #0xFF   ; XOR with 0xFF");
            $display("  0x000E: NOT         ; Invert ACC");
            $display("  0x000F: INC         ; Increment ACC");
            $display("  0x0010: DEC         ; Decrement ACC");
            $display("  0x0011: NOP         ; Halt");
            $display("");
        end
    endtask
    
    // =========================================================================
    // Main Test Sequence
    // =========================================================================
    
    initial begin
        $timeformat(-9, 0, " ns", 8);  // Time format: nanoseconds
        
        $display("");
        $display("********************************************************************************");
        $display("*                                                                              *");
        $display("*                    8-BIT CPU SIMULATION - REAL-TIME MONITOR                    *");
        $display("*                                                                              *");
        $display("********************************************************************************");
        $display("");
        $display("Simulation started at: %0t", $time);
        $display("");
        
        // Initialize signals
        clk = 0;
        reset = 0;
        
        // Load test program
        load_test_program;
        
        // Apply reset
        $display("================================================================================");
        $display("APPLYING RESET");
        $display("================================================================================");
        reset = 1;
        #10;
        reset = 0;
        #10;
        
        // Display initial state
        display_cpu_state("INITIAL STATE AFTER RESET");
        
        // Execute instructions
        $display("");
        $display("================================================================================");
        $display("STARTING INSTRUCTION EXECUTION");
        $display("================================================================================");
        
        // Execute 20 clock cycles to run through the test program
        repeat (20) begin
            @(posedge clk);
            #1;
            display_cpu_state("INSTRUCTION EXECUTION");
        end
        
        // Test Summary
        $display("");
        $display("********************************************************************************");
        $display("*                           SIMULATION SUMMARY                                 *");
        $display("********************************************************************************");
        $display("Total clock cycles: %0d", clock_count);
        $display("Tests passed: %0d", test_passed);
        $display("Tests failed: %0d", test_failed);
        $display("Simulation ended at: %0t", $time);
        $display("********************************************************************************");
        
        #100;
        $finish;
    end
    
    // =========================================================================
    // Timeout Protection
    // =========================================================================
    
    initial begin
        #100000;  // 100us timeout
        $display("");
        $display("TIMEOUT: Simulation exceeded 100us");
        $display("Check the waveform output for debugging.");
        $finish;
    end
    
endmodule
