// ============================================================
// ROM (Read Only Memory)
// 64KB ROM for program storage
// ============================================================

module rom (
    input wire [15:0] addr,      // Address bus
    output reg [7:0] data_out    // Data output
);

    // ROM size: 64KB
    // This would typically be loaded from a file in real implementation
    reg [7:0] memory [0:65535];

    // Initialize ROM with default program (counter)
    initial begin
        // Default program: Increment accumulator in a loop
        // Start with LDA #00, then loop with INC and JMP
        memory[16'h0000] = 8'h01;  // LDA #immediate (opcode)
        memory[16'h0001] = 8'h00;  // Value 00
        memory[16'h0002] = 8'h16;  // INC (increment)
        memory[16'h0003] = 8'h48;  // BRA (branch always)
        memory[16'h0004] = 8'hFC;  // Offset (-4)
        
        // Fill rest with NOP
        memory[16'h0005] = 8'h00;  // NOP
        memory[16'h0006] = 8'h00;  // NOP
        // ... more NOPs
    end

    // Read operation (combinational)
    always @(*) begin
        data_out = memory[addr];
    end

    // Task to load ROM from file (for simulation)
    task load_from_file;
        input [80:0] filename;
        integer fid, i;
        begin
            fid = $fopen(filename, "r");
            if (fid == 0) begin
                $display("Error: Could not open ROM file %s", filename);
            end else begin
                for (i = 0; i < 65536; i = i + 1) begin
                    if (!$feof(fid)) begin
                        $fscanf(fid, "%b", memory[i]);
                    end
                end
                $fclose(fid);
                $display("ROM loaded from %s", filename);
            end
        end
    endtask

endmodule
