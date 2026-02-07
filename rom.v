// ============================================================================
// ROM (Read Only Memory)
// ============================================================================
// 
// ROM provides non-volatile program storage for the CPU. It stores:
// - The program instructions to be executed
// - Fixed data tables (lookup tables, character fonts, etc.)
// 
// Characteristics:
// - Non-volatile memory (contents retained without power)
// - 64KB capacity (65,536 bytes)
// - 8-bit data width (byte-addressable)
// - Read-only (no write capability in normal operation)
// - Asynchronous read (combinational)
// 
// Address Map:
// - 0x0000 - 0x00FF: Primary program storage
// ============================================================================

module rom (
    // Address and data bus
    input wire [15:0] addr,      // 16-bit address bus
    output reg [7:0] data_out    // 8-bit data output
);

    // =========================================================================
    // Memory Array
    // =========================================================================
    // This is the ROM storage array. It is initialized at simulation start
    // with a default program. In actual hardware, ROM would be programmed
    // during manufacturing or via a one-time programming process.
    //
    // Size: 65,536 bytes (64KB)
    
    reg [7:0] memory [0:65535];

    // =========================================================================
    // ROM Initialization with Default Program
    // =========================================================================
    // This initial block loads a simple demonstration program into ROM.
    // The program increments the accumulator in an infinite loop.
    //
    // Default Program:
    // Address  | Opcode | Operand | Description
    // ---------|--------|---------|-------------------------
    // 0x0000   | 0x01   | 0x00    | LDA #0x00 - Load ACC=0
    // 0x0002   | 0x16   |         | INC - Increment ACC
    // 0x0003   | 0x48   | 0xFC    | BRA -3 (branch back)
    //
    // This creates an infinite loop that continuously increments ACC.
    
    initial begin
        // Opcode 0x00: NOP (No Operation) - serves as a placeholder
        
        // Instruction at 0x0000: LDA #00
        // This loads the immediate value 0x00 into the accumulator
        memory[16'h0000] = 8'h01;  // LDA_IMM opcode
        memory[16'h0001] = 8'h00;  // Immediate value 0x00
        
        // Instruction at 0x0002: INC (Increment Accumulator)
        // This adds 1 to the accumulator value
        memory[16'h0002] = 8'h16;  // INC opcode
        
        // Instruction at 0x0003: BRA (Branch Always)
        // This creates an infinite loop by branching back 4 bytes
        // The offset is signed, so 0xFC represents -4
        memory[16'h0003] = 8'h48;  // BRA opcode
        memory[16'h0004] = 8'hFC;  // Branch offset (-4 as two's complement)
        
        // Fill remaining ROM with NOP instructions (0x00)
        // These serve as padding and will execute as no-operations
        for (integer i = 16'h0005; i < 16'h0100; i = i + 1) begin
            memory[i] = 8'h00;  // NOP
        end
    end

    // =========================================================================
    // Read Operation
    // =========================================================================
    // This always block handles read operations. ROM reads are asynchronous -
    // the output changes immediately when the address changes.
    //
    // Read Behavior:
    // - Data appears on data_out immediately when addr changes
    // - ROM is always readable (no read enable needed)
    // - Reads do not consume clock cycles
    
    always @(*) begin
        // Combinational read - output is always valid
        data_out = memory[addr];
    end

endmodule
