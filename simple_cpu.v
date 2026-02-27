// ============================================================================
// Simple 8-bit CPU - Working Version
// ============================================================================
// 
// This is a simplified version that demonstrates the core concepts
// ============================================================================

`timescale 1ns/1ps

// Instruction opcodes
`define LDA_IMM  8'h01
`define LDX_IMM  8'h06
`define LDY_IMM  8'h09
`define ADD_IMM  8'h10
`define SUB_IMM  8'h12
`define AND_IMM  8'h20
`define OR_IMM   8'h22
`define XOR_IMM  8'h24
`define NOT      8'h26
`define INC      8'h16
`define DEC      8'h17
`define NOP      8'h00

module simple_cpu;
    reg clk;
    reg reset;
    
    // Registers
    reg [7:0] acc;
    reg [7:0] x_reg;
    reg [7:0] y_reg;
    reg [15:0] pc;
    reg [7:0] ir;
    reg [7:0] flags;
    
    // Memory
    reg [7:0] rom [0:255];
    reg [7:0] ram [0:65535];
    
    // Buses
    wire [15:0] addr_bus = pc;
    wire [7:0] data_bus;
    
    // Control signals
    wire mem_read = (addr_bus < 16'h0100);
    wire mem_write = 1'b0;
    
    // Memory data
    wire [7:0] mem_data = (addr_bus < 16'h0100) ? rom[addr_bus] : ram[addr_bus];
    
    // Data bus driver
    assign data_bus = mem_read ? mem_data : 8'hZZ;
    
    integer i;
    
    initial begin
        $display("=== Simple 8-bit CPU Simulation ===\n");
        
        clk = 0;
        reset = 0;
        
        // Load program
        rom[0] = `LDA_IMM;  // LDA #0x55
        rom[1] = 8'h55;
        rom[2] = `LDX_IMM;  // LDX #0xAA
        rom[3] = 8'hAA;
        rom[4] = `LDY_IMM;  // LDY #0x33
        rom[5] = 8'h33;
        rom[6] = `ADD_IMM;  // ADD #0x0A
        rom[7] = 8'h0A;
        rom[8] = `SUB_IMM;  // SUB #0x05
        rom[9] = 8'h05;
        rom[10] = `AND_IMM; // AND #0xFF
        rom[11] = 8'hFF;
        rom[12] = `OR_IMM;  // OR #0x0F
        rom[13] = 8'h0F;
        rom[14] = `XOR_IMM; // XOR #0xFF
        rom[15] = 8'hFF;
        rom[16] = `NOT;     // NOT
        rom[17] = `INC;     // INC
        rom[18] = `DEC;     // DEC
        rom[19] = `NOP;     // NOP
        
        for (i = 20; i < 256; i = i + 1) rom[i] = `NOP;
        for (i = 0; i < 65536; i = i + 1) ram[i] = 8'h00;
        
        // Reset
        reset = 1;
        #10;
        reset = 0;
        
        $display("Starting execution...\n");
        $display("Expected: ACC=0x55(85), X=0xAA(170), Y=0x33(51)");
        $display("After ADD: ACC=0x5F(95), After SUB: ACC=0x5A(90)");
        $display("After AND: ACC=0x5A(90), After OR: ACC=0x5F(95)");
        $display("After XOR: ACC=0xA0(160), After NOT: ACC=0x5F(95)");
        $display("After INC: ACC=0x60(96), After DEC: ACC=0x5F(95)\n");
        
        // Execute 25 cycles
        for (i = 0; i < 25; i = i + 1) begin
            @(posedge clk);
            #1;
            $display("Cycle %0d: PC=%04h OP=%02h ACC=%02h X=%02h Y=%02h",
                     i+1, pc, ir, acc, x_reg, y_reg);
        end
        
        $display("\nFinal Results:");
        $display("  ACC = 0x%02h (%0d)", acc, acc);
        $display("  X   = 0x%02h (%0d)", x_reg, x_reg);
        $display("  Y   = 0x%02h (%0d)", y_reg, y_reg);
        
        $display("\nExpected Final Values:");
        $display("  ACC = 0x5F (95)");
        $display("  X   = 0xAA (170)");
        $display("  Y   = 0x33 (51)");
        
        $display("\n=== Simulation Complete ===");
        $finish;
    end
    
    always #5 clk = ~clk;
    
    // Instruction fetch and execute
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            acc <= 8'h00;
            x_reg <= 8'h00;
            y_reg <= 8'h00;
            pc <= 16'h0000;
            ir <= 8'h00;
            flags <= 8'h00;
        end else begin
            // Fetch instruction
            ir <= data_bus;
            pc <= pc + 16'h0001;
            
            // Execute
            case (ir)
                `LDA_IMM: begin
                    acc <= data_bus;
                end
                `LDX_IMM: begin
                    x_reg <= data_bus;
                end
                `LDY_IMM: begin
                    y_reg <= data_bus;
                end
                `ADD_IMM: begin
                    acc <= acc + data_bus;
                end
                `SUB_IMM: begin
                    acc <= acc - data_bus;
                end
                `AND_IMM: begin
                    acc <= acc & data_bus;
                end
                `OR_IMM: begin
                    acc <= acc | data_bus;
                end
                `XOR_IMM: begin
                    acc <= acc ^ data_bus;
                end
                `NOT: begin
                    acc <= ~acc;
                end
                `INC: begin
                    acc <= acc + 8'h01;
                end
                `DEC: begin
                    acc <= acc - 8'h01;
                end
                default: begin
                    // NOP - do nothing
                end
            endcase
        end
    end
    
    initial begin
        #200000;
        $display("Timeout!");
        $finish;
    end
    
endmodule
