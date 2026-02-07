// ============================================================================
// CPU Complete Testbench - Real-Time Monitoring
// ============================================================================
// 
// This testbench provides real-time terminal output showing:
// - Clock cycles
// - Instruction fetch/decode/execute phases
// - All bus signals (data, address, control)
// - Register contents (ACC, X, Y, PC, SP, IR, Flags)
// - ALU operations and results
// - Memory reads and writes
// ============================================================================

`timescale 1ns/1ps

`include "instructions.vh"

module cpu_tb;
    
    // ========================================================================
    // CPU Signals
    // ========================================================================
    
    reg clk;                          // System clock
    reg reset;                        // Reset signal
    
    wire [7:0] data_bus;           // 8-bit data bus
    wire [15:0] addr_bus;          // 16-bit address bus
    wire mem_read;                   // Memory read enable
    wire mem_write;                  // Memory write enable
    wire [7:0] acc_out;            // Accumulator
    wire [15:0] pc_out;            // Program counter
    wire [7:0] flags_out;          // Flags register
    wire [7:0] x_out;               // X register
    wire [7:0] y_out;               // Y register
    wire halt;                       // Halt signal
    
    // ========================================================================
    // Memory Model
    // ========================================================================
    
    reg [7:0] ram [0:65535];
    reg [7:0] rom [0:65535];
    reg [7:0] mem_data_out;
    wire [7:0] rom_data, ram_data;
    
    // ROM/RAM multiplexing
    assign rom_data = (addr_bus < 16'h0100) ? rom[addr_bus] : 8'h00;
    assign ram_data = (addr_bus >= 16'h0100) ? ram[addr_bus] : 8'h00;
    assign mem_data_out = (addr_bus < 16'h0100) ? rom[addr_bus] : ram[addr_bus];
    
    // RAM write
    always @(posedge clk) begin
        if (mem_write && addr_bus >= 16'h0100) begin
            ram[addr_bus] <= acc_out;
        end
    end
    
    // ========================================================================
    // Clock Generation
    // ========================================================================
    
    always #5 clk = ~clk;  // 100MHz clock
    
    // ========================================================================
    // CPU Instance
    // ========================================================================
    
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
    
    // ========================================================================
    // Simulation Variables
    // ========================================================================
    
    integer clock_cycles = 0;
    integer passed = 0;
    integer failed = 0;
    
    // ========================================================================
    // Helper Tasks
    // ========================================================================
    
    task print_separator;
        begin
            $write("\n");
            $write("================================================================================\n");
        end
    endtask
    
    task print_header;
        input [79:0] title;
        begin
            print_separator;
            $write("  %s\n", title);
            print_separator;
        end
    endtask
    
    task print_bus_signals;
        begin
            $write("--- BUS SIGNALS ---\n");
            $write("  CLK:     %b\n", clk);
            $write("  RESET:   %b\n", reset);
            $write("  ADDR:    0x%04h  (Decimal: %0d)\n", addr_bus, addr_bus);
            $write("  DATA:    0x%02h  (Decimal: %0d)\n", data_bus, data_bus);
            $write("  MEM_RD:  %b\n", mem_read);
            $write("  MEM_WR:  %b\n", mem_write);
        end
    endtask
    
    task print_registers;
        begin
            $write("--- CPU REGISTERS ---\n");
            $write("  PC:  0x%04h  (Decimal: %0d)  [Points to next instruction]\n", pc_out, pc_out);
            $write("  ACC: 0x%02h  (Decimal: %0d)  [Primary accumulator]\n", acc_out, acc_out);
            $write("  X:   0x%02h  (Decimal: %0d)  [Index register 1]\n", x_out, x_out);
            $write("  Y:   0x%02h  (Decimal: %0d)  [Index register 2]\n", y_out, y_out);
            $write("  IR:  0x%02h  [Current opcode]\n", rom[pc_out]);
        end
    endtask
    
    task print_flags;
        begin
            $write("--- STATUS FLAGS ---\n");
            $write("  FLAGS: 0x%02h  [Binary: %b]\n", flags_out, flags_out);
            $write("    Bit 0: C (Carry)      = %b  [Arithmetic carry/borrow]\n", flags_out[0]);
            $write("    Bit 1: Z (Zero)      = %b  [Result is zero]\n", flags_out[1]);
            $write("    Bit 2: N (Negative)  = %b  [Result is negative]\n", flags_out[2]);
            $write("    Bit 3: V (Overflow)  = %b  [Signed overflow]\n", flags_out[3]);
            $write("    Bit 4: I (IRQ Disable)= %b  [Interrupt disabled]\n", flags_out[4]);
            $write("    Bit 5: D (Decimal)   = %b  [BCD mode]\n", flags_out[5]);
            $write("    Bit 6: B (Break)     = %b  [Break flag]\n", flags_out[6]);
            $write("    Bit 7: X (Extended)  = %b  [Extended flag]\n", flags_out[7]);
        end
    endtask
    
    task print_memory;
        begin
            $write("--- MEMORY CONTENT ---\n");
            if (addr_bus < 16'h0100) begin
                $write("  ROM[0x%04h] = 0x%02h  [Instruction fetch]\n", addr_bus, rom[addr_bus]);
            end else begin
                $write("  RAM[0x%04h] = 0x%02h  [Data access]\n", addr_bus, ram[addr_bus]);
            end
        end
    endtask
    
    task print_instruction;
        input [7:0] opcode;
        begin
            $write("--- CURRENT INSTRUCTION ---\n");
            case (opcode)
                `OPCODE_NOP:      $write("  Opcode: 0x%02h  [NOP]  No Operation\n", opcode);
                `OPCODE_LDA_IMM:  $write("  Opcode: 0x%02h  [LDA #imm]  Load Accumulator Immediate\n", opcode);
                `OPCODE_LDA_DIR:  $write("  Opcode: 0x%02h  [LDA dir]  Load Accumulator Direct\n", opcode);
                `OPCODE_STA_DIR:  $write("  Opcode: 0x%02h  [STA dir]  Store Accumulator Direct\n", opcode);
                `OPCODE_LDX_IMM:  $write("  Opcode: 0x%02h  [LDX #imm]  Load X Immediate\n", opcode);
                `OPCODE_LDY_IMM:  $write("  Opcode: 0x%02h  [LDY #imm]  Load Y Immediate\n", opcode);
                `OPCODE_ADD_IMM:  $write("  Opcode: 0x%02h  [ADD #imm]  Add Immediate\n", opcode);
                `OPCODE_SUB_IMM:  $write("  Opcode: 0x%02h  [SUB #imm]  Subtract Immediate\n", opcode);
                `OPCODE_MUL:      $write("  Opcode: 0x%02h  [MUL]  Multiply\n", opcode);
                `OPCODE_DIV:      $write("  Opcode: 0x%02h  [DIV]  Divide\n", opcode);
                `OPCODE_AND_IMM:  $write("  Opcode: 0x%02h  [AND #imm]  AND Immediate\n", opcode);
                `OPCODE_OR_IMM:   $write("  Opcode: 0x%02h  [OR #imm]  OR Immediate\n", opcode);
                `OPCODE_XOR_IMM:  $write("  Opcode: 0x%02h  [XOR #imm]  XOR Immediate\n", opcode);
                `OPCODE_NOT:      $write("  Opcode: 0x%02h  [NOT]  NOT Accumulator\n", opcode);
                `OPCODE_INC:      $write("  Opcode: 0x%02h  [INC]  Increment\n", opcode);
                `OPCODE_DEC:      $write("  Opcode: 0x%02h  [DEC]  Decrement\n", opcode);
                `OPCODE_SHL:      $write("  Opcode: 0x%02h  [SHL]  Shift Left\n", opcode);
                `OPCODE_SHR:      $write("  Opcode: 0x%02h  [SHR]  Shift Right\n", opcode);
                `OPCODE_ROL:      $write("  Opcode: 0x%02h  [ROL]  Rotate Left\n", opcode);
                `OPCODE_ROR:      $write("  Opcode: 0x%02h  [ROR]  Rotate Right\n", opcode);
                `OPCODE_BEQ:      $write("  Opcode: 0x%02h  [BEQ]  Branch if Equal\n", opcode);
                `OPCODE_BNE:      $write("  Opcode: 0x%02h  [BNE]  Branch if Not Equal\n", opcode);
                `OPCODE_BRA:      $write("  Opcode: 0x%02h  [BRA]  Branch Always\n", opcode);
                default:          $write("  Opcode: 0x%02h  [Unknown Opcode]\n", opcode);
            endcase
        endtask
    
    task print_full_state;
        input [79:0] phase;
        begin
            clock_cycles = clock_cycles + 1;
            print_separator;
            $write("  CLOCK CYCLE: %0d  |  PHASE: %s\n", clock_cycles, phase);
            print_separator;
            print_bus_signals;
            $write("\n");
            print_registers;
            $write("\n");
            print_flags;
            $write("\n");
            print_instruction(rom[pc_out]);
            print_memory;
            print_separator;
            $write("\n");
        end
    endtask
    
    // ========================================================================
    // Load Test Program
    // ========================================================================
    
    task load_test_program;
        begin
            $write("Loading test program into ROM...\n\n");
            
            // Test program: LDA #55, LDX #AA, ADD #0A, SUB #05, NOP
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
            rom[16'h000C] = `OPCODE_NOT;
            rom[16'h000D] = `OPCODE_NOP;  // Halt
            
            // Fill rest with NOP
            for (integer i = 16'h000E; i < 16'h0100; i = i + 1) begin
                rom[i] = `OPCODE_NOP;
            end
            
            $write("Test Program:\n");
            $write("  0x0000: LDA #0x55  ; Load ACC with 85\n");
            $write("  0x0002: LDX #0xAA  ; Load X with 170\n");
            $write("  0x0004: ADD #0x0A  ; Add 10 to ACC (85+10=95)\n");
            $write("  0x0006: SUB #0x05  ; Subtract 5 from ACC (95-5=90)\n");
            $write("  0x0008: AND #0xFF  ; AND with 255 (no change)\n");
            $write("  0x000A: OR  #0x0F  ; OR with 15\n");
            $write("  0x000C: NOT        ; NOT accumulator\n");
            $write("  0x000D: NOP        ; Halt\n\n");
        end
    endtask
    
    // ========================================================================
    // Main Test Sequence
    // ========================================================================
    
    initial begin
        // Set time format
        $timeformat(-9, 0, " ns", 8);
        
        print_header("8-BIT CPU SIMULATION - REAL-TIME MONITOR");
        $write("Start Time: %0t\n\n", $time);
        
        // Initialize
        clk = 0;
        reset = 0;
        
        // Load program
        load_test_program;
        
        // Apply reset
        print_header("APPLYING RESET");
        reset = 1;
        #10;
        reset = 0;
        #10;
        
        print_full_state("INITIAL STATE AFTER RESET");
        
        // Execute instructions
        print_header("INSTRUCTION EXECUTION PHASE");
        $write("Executing instructions...\n\n");
        
        // Execute 15 clock cycles
        repeat (15) begin
            @(posedge clk);
            #1;
            print_full_state("EXECUTE");
        end
        
        // Summary
        print_header("SIMULATION COMPLETE");
        $write("End Time: %0t\n", $time);
        $write("Total Clock Cycles: %0d\n\n", clock_cycles);
        
        #100;
        $finish;
    end
    
    // ========================================================================
    // Timeout Protection
    // ========================================================================
    
    initial begin
        #100000;  // 100us timeout
        if ($time < 100000) begin
            print_separator;
            $write("TIMEOUT: Simulation exceeded 100us\n");
            print_separator;
            $finish;
        end
    end
    
endmodule
