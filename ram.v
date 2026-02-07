// ============================================================================
// RAM (Random Access Memory)
// ============================================================================
// 
// RAM provides volatile data storage for the CPU. It is used to store:
// - Program variables and data
// - Stack data (at addresses 0x0100-0x01FF)
// - Intermediate calculation results
// - Any data that needs to be modified during program execution
// 
// Characteristics:
// - Volatile memory (contents lost when power is removed)
// - 64KB capacity (65,536 bytes)
// - 8-bit data width (byte-addressable)
// - Synchronous write, asynchronous read
// - Single-port design (one read or write at a time)
// ============================================================================

module ram (
    // Clock and reset signals
    input wire clk,           // System clock - writes are synchronous
    input wire reset,         // Asynchronous reset
    
    // Address and data bus
    input wire [15:0] addr,  // 16-bit address bus (64KB address space)
    input wire [7:0] data_in, // 8-bit data input (for write operations)
    
    // Control signals
    input wire write_enable, // Active-high write enable
    input wire read_enable,  // Active-high read enable
    
    // Outputs
    output reg [7:0] data_out, // 8-bit data output (for read operations)
    output reg ready           // Memory ready signal
);

    // =========================================================================
    // Memory Array
    // =========================================================================
    // This is the actual RAM storage array. It is declared as a 2-dimensional
    // array of 8-bit registers, indexed by a 16-bit address.
    // 
    // Size: 65,536 bytes (64KB)
    // Organization: Linear array, byte-addressable
    // Index range: 0 to 65,535 (16'h0000 to 16'hFFFF)
    
    reg [7:0] memory [0:65535];

    // =========================================================================
    // Memory Initialization
    // =========================================================================
    // This initial block runs once at simulation start (for synthesis,
    // this would typically be replaced by a configuration file or
    // reset-based initialization).
    //
    // All memory locations are initialized to 0x00.
    
    integer i;
    initial begin
        // Initialize all memory locations to zero
        for (i = 0; i < 65536; i = i + 1) begin
            memory[i] = 8'h00;
        end
        
        // Memory is ready after initialization
        ready <= 1'b1;
    end

    // =========================================================================
    // Write Operation
    // =========================================================================
    // This always block handles write operations. Writes are synchronous,
    // occurring on the rising edge of the clock when write_enable is asserted.
    //
    // Write Behavior:
    // - Data is written on the clock rising edge
    // - Only one byte can be written at a time
    // - Address determines which byte is written
    // - write_enable must be high for write to occur
    
    always @(posedge clk) begin
        // Only write when write_enable is asserted
        if (write_enable) begin
            // Write the data_in value to the addressed location
            memory[addr] <= data_in;
        end
    end

    // =========================================================================
    // Read Operation
    // =========================================================================
    // This always block handles read operations. Reads are asynchronous,
    // occurring continuously based on the current address.
    //
    // Read Behavior:
    // - Data appears on data_out immediately when address changes
    // - read_enable controls whether data is driven or high-impedance
    // - When read_enable is low, data_out is high-impedance (tristate)
    //
    // Note: For simulation purposes, we always drive data_out when
    // read_enable is asserted. In actual hardware, this would typically
    // be controlled by tristate drivers.
    
    always @(*) begin
        if (read_enable) begin
            data_out = memory[addr];
        end else begin
            // Tristate when not reading (high impedance)
            data_out = 8'hZZ;
        end
    end

    // =========================================================================
    // Memory Ready Signal
    // =========================================================================
    // This signal indicates that the memory is ready for operations.
    // In this simple implementation, memory is always ready.
    //
    // In a more complex design, this could be used to indicate:
    // - Memory initialization complete
    // - No pending operations
    // - Power-up sequence complete
    
    always @(*) begin
        // Memory is always ready in this implementation
        ready = 1'b1;
    end

    // =========================================================================
    // Memory Access Tasks (for Simulation/Debug)
    // =========================================================================
    // These tasks provide convenient ways to access memory from simulation
    // testbenches and debug routines.
    
    // Read a byte from memory
    task read_byte;
        input [15:0] address;
        output [7:0] value;
        begin
            value = memory[address];
        end
    endtask
    
    // Write a byte to memory
    task write_byte;
        input [15:0] address;
        input [7:0] value;
        begin
            memory[address] = value;
        end
    endtask
    
    // Fill a range of memory with a value
    task fill_range;
        input [15:0] start_addr;
        input [15:0] end_addr;
        input [7:0] value;
        integer j;
        begin
            for (j = start_addr; j <= end_addr; j = j + 1) begin
                memory[j] = value;
            end
        end
    endtask
    
    // Dump memory contents to console (for debugging)
    task dump_memory;
        input [15:0] start_addr;
        input [15:0] end_addr;
        integer j;
        begin
            $display("Memory Dump from 0x%04h to 0x%04h:", start_addr, end_addr);
            for (j = start_addr; j <= end_addr; j = j + 1) begin
                if ((j % 16) == 0) begin
                    if (j != start_addr) $display("");
                    $write("%04h: ", j);
                end
                $write("%02h ", memory[j]);
            end
            $display("");
        end
    endtask

endmodule
