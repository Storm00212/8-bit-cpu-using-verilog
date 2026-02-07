// ============================================================================
// ROM (Read Only Memory)
// ============================================================================
// 
// ROM provides non-volatile program storage for the CPU. It stores:
// - The program instructions to be executed
// - Fixed data tables (lookup tables, character fonts, etc.)
// - Boot code (in some architectures)
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

    // =========================================================================
    // ROM Loading Task
    // =========================================================================
    // This task allows loading ROM contents from an external file.
    // It is primarily used for simulation to load custom programs.
    //
    // File Format:
    // - ASCII text file with one byte per line
    // - Each line contains an 8-bit binary value
    // - Example: "00000001" for opcode 0x01
    //
    // Usage:
    // initial begin
    //     rom.load_from_file("program.bin");
    // end
    
    task load_from_file;
        input [80:0] filename;     // File path (up to 80 chars + null)
        integer fid, i;
        begin
            // Open the file for reading
            fid = $fopen(filename, "r");
            
            // Check if file opened successfully
            if (fid == 0) begin
                $display("Error: Could not open ROM file %s", filename);
            end else begin
                // Read all 65,536 bytes from the file
                for (i = 0; i < 65536; i = i + 1) begin
                    // Check for end of file before reading
                    if (!$feof(fid)) begin
                        // Read binary value (format: %b for binary)
                        $fscanf(fid, "%b", memory[i]);
                    end
                end
                
                // Close the file
                $fclose(fid);
                
                // Confirm successful load
                $display("ROM loaded successfully from %s", filename);
            end
        end
    endtask

    // =========================================================================
    // ROM Verification Task
    // =========================================================================
    // This task verifies ROM contents against expected values.
    // Useful for testing and debugging.
    
    task verify_contents;
        input [15:0] start_addr;
        input [15:0] end_addr;
        input [7:0] expected_value;
        output integer error_count;
        integer j;
        begin
            error_count = 0;
            for (j = start_addr; j <= end_addr; j = j + 1) begin
                if (memory[j] != expected_value) begin
                    $display("ROM verification error at 0x%04h: expected 0x%02h, got 0x%02h",
                             j, expected_value, memory[j]);
                    error_count = error_count + 1;
                end
            end
        end
    endtask

    // =========================================================================
    // ROM Information Task
    // =========================================================================
    // This task displays information about the ROM contents.
    
    task report_contents;
        integer j;
        integer opcode_count;
        begin
            opcode_count = 0;
            for (j = 0; j < 256; j = j + 1) begin
                if (memory[j] != 8'h00) begin
                    opcode_count = opcode_count + 1;
                end
            end
            
            $display("ROM Contents Report:");
            $display("  Total size: 65536 bytes");
            $display("  Non-zero bytes: %0d", opcode_count);
            $display("  First 16 bytes:");
            for (j = 0; j < 16; j = j + 1) begin
                $display("    0x%04h: 0x%02h", j, memory[j]);
            end
        end
    endtask

endmodule
