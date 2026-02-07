// ============================================================================
// ROM (Read Only Memory) - External Memory Version
// ============================================================================
// 
// ROM provides non-volatile program storage for the CPU.
// This version accepts the memory array from an external source (testbench).
// ============================================================================

module rom (
    // Address and data bus
    input wire [15:0] addr,      // 16-bit address bus
    output wire [7:0] data_out,   // 8-bit data output
    
    // External memory interface
    input wire [7:0] mem_data [0:65535]  // External memory array
);

    // Read Operation - Direct Assignment
    assign data_out = mem_data[addr];

endmodule
