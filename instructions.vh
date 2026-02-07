// ============================================================
// Instruction Set Architecture Definitions
// 8-bit CPU with 16-bit addressing (64KB memory space)
// ============================================================

// Opcode definitions (8-bit)
`define OPCODE_NOP       8'h00  // No operation
`define OPCODE_LDA_IMM   8'h01  // Load Accumulator immediate
`define OPCODE_LDA_DIR   8'h02  // Load Accumulator direct
`define OPCODE_LDA_IND   8'h03  // Load Accumulator indirect
`define OPCODE_STA_DIR   8'h04  // Store Accumulator direct
`define OPCODE_STA_IND   8'h05  // Store Accumulator indirect
`define OPCODE_LDX_IMM   8'h06  // Load X register immediate
`define OPCODE_LDX_DIR   8'h07  // Load X register direct
`define OPCODE_STX_DIR   8'h08  // Store X register direct
`define OPCODE_LDY_IMM   8'h09  // Load Y register immediate
`define OPCODE_LDY_DIR   8'h0A  // Load Y register direct
`define OPCODE_STY_DIR   8'h0B  // Store Y register direct

// Arithmetic operations
`define OPCODE_ADD_IMM   8'h10  // Add immediate to accumulator
`define OPCODE_ADD_DIR   8'h11  // Add direct memory to accumulator
`define OPCODE_SUB_IMM   8'h12  // Subtract immediate from accumulator
`define OPCODE_SUB_DIR   8'h13  // Subtract direct memory from accumulator
`define OPCODE_MUL       8'h14  // Multiply accumulator by X register
`define OPCODE_DIV       8'h15  // Divide accumulator by X register
`define OPCODE_INC       8'h16  // Increment accumulator
`define OPCODE_DEC       8'h17  // Decrement accumulator
`define OPCODE_ADC       8'h18  // Add with carry
`define OPCODE_SBC       8'h19  // Subtract with borrow

// Logical operations
`define OPCODE_AND_IMM   8'h20  // AND immediate with accumulator
`define OPCODE_AND_DIR   8'h21  // AND direct memory with accumulator
`define OPCODE_OR_IMM    8'h22  // OR immediate with accumulator
`define OPCODE_OR_DIR    8'h23  // OR direct memory with accumulator
`define OPCODE_XOR_IMM   8'h24  // XOR immediate with accumulator
`define OPCODE_XOR_DIR   8'h25  // XOR direct memory with accumulator
`define OPCODE_NOT       8'h26  // NOT accumulator
`define OPCODE_CLR       8'h27  // Clear accumulator

// Shift and Rotate operations
`define OPCODE_SHL       8'h28  // Shift left accumulator
`define OPCODE_SHR       8'h29  // Shift right accumulator
`define OPCODE_ROL       8'h2A  // Rotate left accumulator
`define OPCODE_ROR       8'h2B  // Rotate right accumulator
`define OPCODE_SHL_DIR   8'h2C  // Shift left memory
`define OPCODE_SHR_DIR   8'h2D  // Shift right memory

// Compare and Test operations
`define OPCODE_CMP_IMM   8'h30  // Compare accumulator with immediate
`define OPCODE_CMP_DIR   8'h31  // Compare accumulator with memory
`define OPCODE_CPX_IMM   8'h32  // Compare X with immediate
`define OPCODE_CPY_IMM   8'h33  // Compare Y with immediate
`define OPCODE_TST       8'h34  // Test bits in memory

// Branch operations
`define OPCODE_BEQ       8'h40  // Branch if equal (Z=1)
`define OPCODE_BNE       8'h41  // Branch if not equal (Z=0)
`define OPCODE_BMI       8'h42  // Branch if minus (N=1)
`define OPCODE_BPL       8'h43  // Branch if plus (N=0)
`define OPCODE_BVS       8'h44  // Branch if overflow (V=1)
`define OPCODE_BVC       8'h45  // Branch if no overflow (V=0)
`define OPCODE_BCS       8'h46  // Branch if carry set (C=1)
`define OPCODE_BCC       8'h47  // Branch if carry clear (C=0)
`define OPCODE_BRA       8'h48  // Branch always

// Jump and Call operations
`define OPCODE_JMP_DIR   8'h50  // Jump to direct address
`define OPCODE_JMP_IND   8'h51  // Jump to indirect address
`define OPCODE_JSR       8'h52  // Jump to subroutine
`define OPCODE_RTS       8'h53  // Return from subroutine

// Stack operations
`define OPCODE_PHA       8'h60  // Push accumulator onto stack
`define OPCODE_PLA       8'h61  // Pull accumulator from stack
`define OPCODE_PHX       8'h62  // Push X register onto stack
`define OPCODE_PLX       8'h63  // Pull X register from stack
`define OPCODE_PHY       8'h64  // Push Y register onto stack
`define OPCODE_PLY       8'h65  // Pull Y register from stack
`define OPCODE_PHP       8'h66  // Push processor status
`define OPCODE_PLP       8'h67  // Pull processor status

// Scientific/Math operations
`define OPCODE_SQRT      8'h70  // Square root of accumulator
`define OPCODE_SQUARE    8'h71  // Square of accumulator
`define OPCODE_ABS       8'h72  // Absolute value of accumulator
`define OPCODE_NEG       8'h73  // Negate accumulator (two's complement)
`define OPCODE_EXP       8'h74  // e^x approximation
`define OPCODE_LOG       8'h75  // Natural log approximation
`define OPCODE_SIN       8'h76  // Sine approximation
`define OPCODE_COS       8'h77  // Cosine approximation
`define OPCODE_TAN       8'h78  // Tangent approximation
`define OPCODE_POW       8'h79  // Power (accumulator ^ X register)

// Flag register bits
`define FLAG_CARRY       0     // Carry flag
`define FLAG_ZERO        1     // Zero flag
`define FLAG_SIGN        2     // Sign flag (negative)
`define FLAG_OVERFLOW    3     // Overflow flag
`define FLAG_IRQ_DISABLE 4     // Interrupt disable
`define FLAG_DECIMAL     5     // Decimal mode flag
`define FLAG_BREAK       6     // Break flag
`define FLAG_EXTENDED    7     // Extended flag

// Memory sizes
`define RAM_SIZE         16'h10000  // 64KB RAM
`define ROM_SIZE         16'h10000  // 64KB ROM
`define STACK_SIZE       8'h100     // 256 bytes stack

// Address constants
`define STACK_TOP        16'h0100   // Stack starts at 0x0100
`define STACK_BOTTOM     16'h01FF   // Stack ends at 0x01FF
