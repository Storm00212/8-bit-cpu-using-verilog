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
    // Memory Array - Public for testbench initialization
    // =========================================================================
    // This is the ROM storage array. It is initialized at simulation start.
    // The memory array is public so the testbench can initialize it.
    //
    // Size: 65,536 bytes (64KB)
    
    (* public *) reg [7:0] memory [0:65535];

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
