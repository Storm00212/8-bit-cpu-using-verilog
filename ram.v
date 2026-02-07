// ============================================================
// RAM (Random Access Memory)
// 64KB RAM with read/write capabilities
// ============================================================

module ram (
    input wire        clk,           // Clock
    input wire        reset,         // Reset
    input wire [15:0] addr,          // Address bus
    input wire [7:0]  data_in,       // Data input
    input wire        write_enable,  // Write enable
    input wire        read_enable,   // Read enable
    output reg [7:0]  data_out,      // Data output
    output reg        ready          // Memory ready signal
);

    // RAM size: 64KB
    reg [7:0] memory [0:65535];

    // Initialize RAM contents
    integer i;
    initial begin
        for (i = 0; i < 65536; i = i + 1) begin
            memory[i] = 8'h00;
        end
        ready <= 1'b1;
    end

    // Write operation
    always @(posedge clk) begin
        if (write_enable) begin
            memory[addr] <= data_in;
        end
    end

    // Read operation (combinational)
    always @(*) begin
        if (read_enable) begin
            data_out = memory[addr];
        end else begin
            data_out = 8'hZZ;
        end
    end

    // Memory ready (always ready in this simple model)
    always @(*) begin
        ready = 1'b1;
    end

endmodule
