// ============================================================================
// ROM (Read Only Memory) - Simplified Version
// ============================================================================
// 
// ROM provides non-volatile program storage for the CPU. It stores:
// - The program instructions to be executed
// - Fixed data tables
// 
// Characteristics:
// - Non-volatile memory
// - 64KB capacity
// - 8-bit data width
// - Read-only
// - Asynchronous read
// ============================================================================

module rom (
    // Address and data bus
    input wire [15:0] addr,      // 16-bit address bus
    output wire [7:0] data_out    // 8-bit data output
);

    // =========================================================================
    // Memory Array
    // =========================================================================
    
    reg [7:0] memory [0:65535];

    // =========================================================================
    // Read Operation - Direct Assignment
    // =========================================================================
    
    assign data_out = memory[addr];

endmodule
