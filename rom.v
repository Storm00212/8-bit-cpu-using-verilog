// ============================================================================
// ROM (Read Only Memory) - Simple Version
// ============================================================================
// 
// ROM provides non-volatile program storage for the CPU.
// This version has a simple interface without array ports.
// ============================================================================

module rom (
    // Address and data bus
    input wire [15:0] addr,      // 16-bit address bus
    output reg [7:0] data_out    // 8-bit data output
);

    // Memory array
    reg [7:0] memory [0:65535];

    // Read operation
    always @(*) begin
        data_out = memory[addr];
    end

endmodule
