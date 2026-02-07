// ============================================================================
// Instruction Set Architecture Definitions
// 8-bit CPU with 16-bit addressing (64KB memory space)
// ============================================================================
// 
// This header file defines all opcodes, flags, and memory constants used
// by the 8-bit CPU. These definitions provide a centralized location for
// all instruction-related constants.
// ============================================================================

// Opcode definitions (8-bit)
// Each opcode represents a specific instruction that the CPU can execute.
// The CPU uses these 8-bit values to decode and perform operations.

// No-operation instruction - does nothing, advances to next instruction
`define OPCODE_NOP       8'h00  

// Load Accumulator instructions - transfer data into the accumulator register
// Immediate mode: loads the following byte directly into ACC
`define OPCODE_LDA_IMM   8'h01  
// Direct mode: loads data from the specified memory address into ACC
`define OPCODE_LDA_DIR   8'h02  
// Indirect mode: loads data from the address stored at the specified location
`define OPCODE_LDA_IND   8'h03  

// Store Accumulator instructions - transfer data from ACC to memory
// Direct mode: stores ACC value to the specified memory address
`define OPCODE_STA_DIR   8'h04  
// Indirect mode: stores ACC to the address stored at the specified location
`define OPCODE_STA_IND   8'h05  

// Load X Register instructions - transfer data into the X index register
// Immediate mode: loads the following byte directly into X
`define OPCODE_LDX_IMM   8'h06  
// Direct mode: loads data from memory into X register
`define OPCODE_LDX_DIR   8'h07  

// Store X Register - transfers data from X to memory
// Direct mode: stores X value to the specified memory address
`define OPCODE_STX_DIR   8'h08  

// Load Y Register instructions - transfer data into the Y index register
// Immediate mode: loads the following byte directly into Y
`define OPCODE_LDY_IMM   8'h09  
// Direct mode: loads data from memory into Y register
`define OPCODE_LDY_DIR   8'h0A  

// Store Y Register - transfers data from Y to memory
// Direct mode: stores Y value to the specified memory address
`define OPCODE_STY_DIR   8'h0B  

// ============================================================================
// Arithmetic Operations
// ============================================================================
// These instructions perform mathematical calculations on the accumulator
// using either immediate values or values from memory locations.

// Add Immediate - adds the following byte value to the accumulator
`define OPCODE_ADD_IMM   8'h10  
// Add Direct - adds the value at the specified memory address to ACC
`define OPCODE_ADD_DIR   8'h11  

// Subtract Immediate - subtracts the following byte from the accumulator
`define OPCODE_SUB_IMM   8'h12  
// Subtract Direct - subtracts the value at the memory address from ACC
`define OPCODE_SUB_DIR   8'h13  

// Multiply - multiplies the accumulator by the X register (8-bit result)
`define OPCODE_MUL       8'h14  

// Divide - divides the accumulator by the X register (returns quotient)
`define OPCODE_DIV       8'h15  

// Increment - adds 1 to the accumulator
`define OPCODE_INC       8'h16  

// Decrement - subtracts 1 from the accumulator
`define OPCODE_DEC       8'h17  

// Add with Carry - adds the operand plus the carry flag to accumulator
// Used for multi-byte addition operations
`define OPCODE_ADC       8'h18  

// Subtract with Borrow - subtracts the operand plus inverted carry from ACC
// Used for multi-byte subtraction operations
`define OPCODE_SBC       8'h19  

// ============================================================================
// Logical Operations
// ============================================================================
// These instructions perform bitwise logical operations on the accumulator
// which are essential for data manipulation and bit masking.

// AND Immediate - bitwise AND the following byte with accumulator
`define OPCODE_AND_IMM   8'h20  
// AND Direct - bitwise AND the memory value with accumulator
`define OPCODE_AND_DIR   8'h21  

// OR Immediate - bitwise OR the following byte with accumulator
`define OPCODE_OR_IMM    8'h22  
// OR Direct - bitwise OR the memory value with accumulator
`define OPCODE_OR_DIR    8'h23  

// XOR Immediate - bitwise XOR the following byte with accumulator
`define OPCODE_XOR_IMM   8'h24  
// XOR Direct - bitwise XOR the memory value with accumulator
`define OPCODE_XOR_DIR   8'h25  

// NOT - performs bitwise complement (inverts all bits) of accumulator
`define OPCODE_NOT       8'h26  

// Clear - sets the accumulator to zero
`define OPCODE_CLR       8'h27  

// ============================================================================
// Shift and Rotate Operations
// ============================================================================
// These instructions shift or rotate bits within the accumulator or memory.
// They are used for bit manipulation, multiplication by powers of 2, etc.

// Shift Left - moves all bits one position to the left, LSB becomes 0
// Bit 7 moves into the Carry flag
`define OPCODE_SHL       8'h28  

// Shift Right - moves all bits one position to the right, MSB becomes 0
// Bit 0 moves into the Carry flag
`define OPCODE_SHR       8'h29  

// Rotate Left - rotates all bits one position to the left through carry
// Bit 7 moves to Carry, Carry moves into Bit 0
`define OPCODE_ROL       8'h2A  

// Rotate Right - rotates all bits one position to the right through carry
// Bit 0 moves to Carry, Carry moves into Bit 7
`define OPCODE_ROR       8'h2B  

// Shift Left Direct - shifts the value at the specified memory address
`define OPCODE_SHL_DIR   8'h2C  

// Shift Right Direct - shifts the value at the specified memory address
`define OPCODE_SHR_DIR   8'h2D  

// ============================================================================
// Compare and Test Operations
// ============================================================================
// These instructions compare values and set flags without changing
// the accumulator. They are used for conditional branching.

// Compare Immediate - compares accumulator with following byte
// Sets Zero flag if equal, Negative flag based on result
`define OPCODE_CMP_IMM   8'h30  
// Compare Direct - compares accumulator with value at memory address
`define OPCODE_CMP_DIR   8'h31  

// Compare X Immediate - compares X register with following byte
`define OPCODE_CPX_IMM   8'h32  

// Compare Y Immediate - compares Y register with following byte
`define OPCODE_CPY_IMM   8'h33  

// Test Bits - tests the bits of the value at the memory address
// Sets Zero flag if all tested bits are zero
`define OPCODE_TST       8'h34  

// ============================================================================
// Branch Operations
// ============================================================================
// These instructions allow the program to change execution flow based
// on the current state of the flags register.

// Branch if Equal - jumps if the Zero flag is set (previous comparison was equal)
`define OPCODE_BEQ       8'h40  
// Branch if Not Equal - jumps if the Zero flag is clear
`define OPCODE_BNE       8'h41  
// Branch if Minus - jumps if the Negative flag is set (result was negative)
`define OPCODE_BMI       8'h42  
// Branch if Plus - jumps if the Negative flag is clear
`define OPCODE_BPL       8'h43  
// Branch if Overflow Set - jumps if the Overflow flag is set
`define OPCODE_BVS       8'h44  
// Branch if Overflow Clear - jumps if the Overflow flag is clear
`define OPCODE_BVC       8'h45  
// Branch if Carry Set - jumps if the Carry flag is set
`define OPCODE_BCS       8'h46  
// Branch if Carry Clear - jumps if the Carry flag is clear
`define OPCODE_BCC       8'h47  
// Branch Always - unconditional jump to the specified offset
`define OPCODE_BRA       8'h48  

// ============================================================================
// Jump and Call Operations
// ============================================================================
// These instructions allow the program to jump to different memory locations
// for subroutine calls and program flow control.

// Jump Direct - unconditionally jumps to the specified memory address
`define OPCODE_JMP_DIR   8'h50  
// Jump Indirect - jumps to the address stored at the specified location
`define OPCODE_JMP_IND   8'h51  
// Jump to Subroutine - saves return address and jumps to subroutine
`define OPCODE_JSR       8'h52  
// Return from Subroutine - returns from a called subroutine
`define OPCODE_RTS       8'h53  

// ============================================================================
// Stack Operations
// ============================================================================
// The stack is a LIFO (Last In, First Out) data structure used for
// saving registers, passing parameters, and managing subroutine returns.
// The stack grows downward from 0x01FF to 0x0100.

// Push Accumulator - saves the accumulator value onto the stack
`define OPCODE_PHA       8'h60  
// Pull Accumulator - retrieves a value from the stack into accumulator
`define OPCODE_PLA       8'h61  
// Push X Register - saves the X register value onto the stack
`define OPCODE_PHX       8'h62  
// Pull X Register - retrieves a value from the stack into X register
`define OPCODE_PLX       8'h63  
// Push Y Register - saves the Y register value onto the stack
`define OPCODE_PHY       8'h64  
// Pull Y Register - retrieves a value from the stack into Y register
`define OPCODE_PLY       8'h65  
// Push Processor Status - saves the flags register onto the stack
`define OPCODE_PHP       8'h66  
// Pull Processor Status - retrieves the flags register from the stack
`define OPCODE_PLP       8'h67  

// ============================================================================
// Scientific/Mathematical Operations
// ============================================================================
// These instructions perform advanced mathematical calculations
// using polynomial approximations and iterative algorithms.

// Square Root - calculates the integer square root of the accumulator
// Uses binary search algorithm for fast approximation
`define OPCODE_SQRT      8'h70  

// Square - calculates the square of the accumulator value
`define OPCODE_SQUARE    8'h71  

// Absolute Value - returns the absolute value of the accumulator
`define OPCODE_ABS       8'h72  

// Negate - calculates the two's complement negation of accumulator
`define OPCODE_NEG       8'h73  

// Exponential - calculates e^x approximation using Taylor series
`define OPCODE_EXP       8'h74  

// Natural Logarithm - calculates ln(x) approximation
`define OPCODE_LOG       8'h75  

// Sine - calculates sin(x) using Taylor series approximation
// Input is scaled angle in radians
`define OPCODE_SIN       8'h76  

// Cosine - calculates cos(x) using Taylor series approximation
// Input is scaled angle in radians
`define OPCODE_COS       8'h77  

// Tangent - calculates tan(x) using sin/cos approximation
`define OPCODE_TAN       8'h78  

// Power - calculates accumulator raised to the power of X register
// Uses repeated multiplication approximation
`define OPCODE_POW       8'h79  

// ============================================================================
// Flag Register Bit Positions
// ============================================================================
// The flags register (also called the Status Register or Condition Code Register)
// contains individual bits that indicate the results of arithmetic and
// logical operations. These flags are used by conditional branch instructions.

// Carry flag - set when an addition operation produces a carry out of bit 7
// or when a subtraction operation requires a borrow
`define FLAG_CARRY       0     

// Zero flag - set when the result of an operation is zero
`define FLAG_ZERO        1     

// Sign/Negative flag - set when the result is negative (bit 7 is 1)
`define FLAG_SIGN        2     

// Overflow flag - set when a signed arithmetic operation produces overflow
// (when the sign of the result is different from expected)
`define FLAG_OVERFLOW    3     

// Interrupt Disable - when set, prevents the CPU from responding to interrupts
`define FLAG_IRQ_DISABLE 4     

// Decimal Mode - when set, arithmetic operations use BCD (Binary Coded Decimal)
// instead of binary representation
`define FLAG_DECIMAL     5     

// Break flag - set when a BRK instruction is executed
`define FLAG_BREAK       6     

// Extended flag - used for additional status information
`define FLAG_EXTENDED    7     

// ============================================================================
// Memory Size Definitions
// ============================================================================
// These constants define the memory organization of the CPU.
// The CPU uses a von Neumann architecture with shared program and data memory.

// Total RAM size - 64KB of data memory (2^16 = 65,536 bytes)
`define RAM_SIZE         16'h10000  

// Total ROM size - 64KB of program memory
`define ROM_SIZE         16'h10000  

// Stack size - 256 bytes dedicated for stack operations
`define STACK_SIZE       8'h100     

// ============================================================================
// Address Constants
// ============================================================================
// These constants define special memory addresses used by the CPU.

// Stack top address - the stack grows downward from this address
// Stack starts at 0x0100 (256 decimal) and grows toward 0x01FF
`define STACK_TOP        16'h0100   
// Stack bottom address - the lowest address the stack can reach
`define STACK_BOTTOM     16'h01FF   
