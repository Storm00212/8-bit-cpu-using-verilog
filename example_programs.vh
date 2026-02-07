// ============================================================
// Example Programs for 8-bit CPU
// ============================================================

// ============================================================
// Program 1: Basic Calculator
// Demonstrates: ADD, SUB, MUL, DIV
// ============================================================
/*
Address | Opcode | Operand | Description
--------|--------|---------|-------------
0x0000  | 01     | 0A      | LDA #10      ; Load accumulator with 10
0x0002  | 06     | 05      | LDX #5       ; Load X with 5
0x0004  | 14     |         | MUL          ; A = A * X (50)
0x0005  | 10     | 02      | ADD #2       ; A = 50 + 2 = 52
0x0007  | 12     | 0A      | SUB #10      ; A = 52 - 10 = 42
0x0009  | 15     |         | DIV          ; A = 42 / 5 = 8
0x000A  | 04     | 20      | STA 0x20     ; Store result at 0x0020
0x000C  | 00     |         | NOP          ; Halt
*/

// ============================================================
// Program 2: Factorial Calculation
// Calculates 5! = 120
// ============================================================
/*
Address | Opcode | Operand | Description
--------|--------|---------|-------------
0x0000  | 01     | 05      | LDA #5       ; Load n = 5
0x0002  | 09     | 01      | LDY #1       ; Load result = 1
0x0004  | 06     | 01      | LDX #1       ; Load i = 1
0x0006  | 31     | 0A      | CMP #10      ; Compare i with 10 (n!)
0x0008  | 41     | 12      | BNE loop     ; Branch if not equal
0x000A  | 04     | 30      | STA 0x30     ; Store result
0x000C  | 00     |         | NOP          ; Halt
0x000E  | 14     |         | MUL          ; result *= i
0x000F  | 16     |         | INC          ; i++
0x0010  | 06     | 01      | LDX #1       ; Reload i
0x0012  | 10     | 01      | ADD #1       ; i + 1
0x0014  | 08     | 00      | STX 0x00     ; Store i
0x0016  | 48     | EE      | BRA loop     ; Loop back
*/

// ============================================================
// Program 3: Fibonacci Sequence
// Generates first 8 Fibonacci numbers
// ============================================================
/*
Address | Opcode | Operand | Description
--------|--------|---------|-------------
0x0000  | 01     | 00      | LDA #0       ; A = 0
0x0002  | 04     | 80      | STA 0x80     ; fib[0] = 0
0x0004  | 01     | 01      | LDA #1       ; A = 1
0x0006  | 04     | 81      | STA 0x81     ; fib[1] = 1
0x0008  | 06     | 02      | LDX #2       ; i = 2
0x000A  | 09     | 08      | LDY #8       ; count = 8
0x000C  | 30     | 08      | CPY #8       ; Check if done
0x000E  | 41     | 24      | BNE cont     ; Continue if not done
0x0010  | 00     |         | NOP          ; Halt
0x0012  | 02     | 80      | LDA 0x80     ; Load fib[i-2]
0x0014  | 02     | 81      | LDX 0x81     ; Load fib[i-1]
0x0016  | 10     |         | ADD X        ; A = fib[i-2] + fib[i-1]
0x0017  | 04     |         | STA 0xXX     ; Store fib[i]
0x0018  | 08     | 81      | STX 0x81     ; Update fib[i-1]
0x001A  | 01     |         | LDA          ; A = fib[i]
0x001B  | 04     | 80      | STA 0x80     ; Update fib[i-2]
0x001D  | 16     |         | INC          ; i++
0x001E  | 48     | E8      | BRA loop     ; Loop
*/

// ============================================================
// Program 4: Data Processing with Memory
// Demonstrates: Load/Store, Logical Operations
// ============================================================
/*
Address | Opcode | Operand | Description
--------|--------|---------|-------------
0x0000  | 01     | FF      | LDA #FF      ; Load 0xFF
0x0002  | 04     | 10      | STA 0x10     ; Store at 0x0010
0x0004  | 01     | 0F      | LDA #0F      ; Load 0x0F
0x0006  | 04     | 11      | STA 0x11     ; Store at 0x0011
0x0008  | 02     | 10      | LDA 0x10     ; Load from 0x0010
0x000A  | 21     | 11      | AND 0x11     ; AND with 0x0011
0x000C  | 04     | 12      | STA 0x12     ; Store result
0x000E  | 02     | 10      | LDA 0x10     ; Load 0x0010
0x0010  | 23     | 11      | OR 0x11      ; OR with 0x0011
0x0012  | 04     | 13      | STA 0x13     ; Store result
0x0014  | 02     | 10      | LDA 0x10     ; Load 0x0010
0x0016  | 25     | 11      | XOR 0x11     ; XOR with 0x0011
0x0018  | 04     | 14      | STA 0x14     ; Store result
0x001A  | 00     |         | NOP          ; Halt
*/

// ============================================================
// Program 5: Bit Manipulation
// Demonstrates: Shift, Rotate, Bit Testing
// ============================================================
/*
Address | Opcode | Operand | Description
--------|--------|---------|-------------
0x0000  | 01     | 55      | LDA #0x55    ; Load 01010101
0x0002  | 28     |         | SHL          ; Shift left (10101010)
0x0003  | 04     | 20      | STA 0x20     ; Store shifted value
0x0005  | 01     | AA      | LDA #0xAA    ; Load 10101010
0x0007  | 2A     |         | ROL          ; Rotate left (01010101 + carry)
0x0008  | 04     | 21      | STA 0x21     ; Store rotated value
0x000A  | 01     | 55      | LDA #0x55    ; Load 01010101
0x000C  | 29     |         | SHR          ; Shift right (00101010)
0x000D  | 04     | 22      | STA 0x22     ; Store shifted value
0x000F  | 01     | 55      | LDA #0x55    ; Load 01010101
0x0011  | 2B     |         | ROR          ; Rotate right (10101010)
0x0012  | 04     | 23      | STA 0x23     ; Store rotated value
0x0014  | 00     |         | NOP          ; Halt
*/

// ============================================================
// Program 6: Conditional Branching
// Demonstrates: Compare and Branch Operations
// ============================================================
/*
Address | Opcode | Operand | Description
--------|--------|---------|-------------
0x0000  | 01     | 0A      | LDA #10      ; Load 10
0x0002  | 30     | 05      | CMP #5       ; Compare with 5
0x0004  | 40     | 0A      | BEQ equal     ; Branch if equal (no)
0x0006  | 41     | 0D      | BNE not_equal ; Branch if not equal (yes)
0x0008  | 04     | 30      | STA 0x30     ; Store "not equal"
0x000A  | 48     | 10      | BRA done
0x000C  | 04     | 31      | STA 0x31     ; Store "equal"
0x000E  | 00     |         | NOP          ; Halt
*/

// ============================================================
// Program 7: Scientific Calculation (Square Root)
// ============================================================
/*
Address | Opcode | Operand | Description
--------|--------|---------|-------------
0x0000  | 01     | 40      | LDA #64      ; Load value to take square root
0x0002  | 70     |         | SQRT         ; Calculate square root
0x0003  | 04     | 50      | STA 0x50     ; Store result (should be 8)
0x0005  | 01     | 10      | LDA #16      ; Load 16
0x0007  | 71     |         | SQUARE       ; Calculate square
0x0008  | 04     | 51      | STA 0x51     ; Store result (should be 256, saturates)
0x000A  | 01     | 0A      | LDA #10      ; Load 10
0x000C  | 72     |         | ABS          ; Absolute value
0x000D  | 04     | 52      | STA 0x52     ; Store result
0x000F  | 01     | 80      | LDA #128     ; Load -128 in two's complement
0x0011  | 73     |         | NEG          ; Negate
0x0012  | 04     | 53      | STA 0x53     ; Store result (should be 128)
0x0014  | 00     |         | NOP          ; Halt
*/

// ============================================================
// Program 8: Stack Operations
// Demonstrates: Push/Pull, Subroutine Calls
// ============================================================
/*
Address | Opcode | Operand | Description
--------|--------|---------|-------------
0x0000  | 01     | 42      | LDA #42      ; Load value
0x0002  | 60     |         | PHA          ; Push A to stack
0x0003  | 01     | 99      | LDA #99      ; Load new value
0x0005  | 61     |         | PLA          ; Pull from stack
0x0006  | 04     | 60      | STA 0x60     ; Store original value
0x0008  | 52     | 20      | JSR sub      ; Jump to subroutine
0x000A  | 00     |         | NOP          ; Halt

; Subroutine at 0x0020
0x0020  | 01     | 55      | LDA #55      ; Load subroutine value
0x0022  | 62     |         | PHX          ; Push X
0x0023  | 01     | 77      | LDX #77      ; Load X
0x0025  | 63     |         | PLX          ; Pull X
0x0026  | 53     |         | RTS          ; Return from subroutine
*/

// ============================================================
// Program 9: Temperature Conversion (Celsius to Fahrenheit)
// Formula: F = (C × 9/5) + 32
// ============================================================
/*
Address | Opcode | Operand | Description
--------|--------|---------|-------------
0x0000  | 01     | 19      | LDA #25      ; Load Celsius (25°C)
0x0002  | 14     |         | MUL          ; A = 25 * X (X should be loaded first)
0x0003  | 10     | 05      | ADD #5       ; A = 25 * 5 = 125
0x0005  | 10     | 04      | ADD #4       ; A = 125 + 4 = 129
0x0007  | 15     |         | DIV          ; A = 129 / 9 ≈ 14
0x0008  | 10     | 20      | ADD #32      ; A = 14 + 32 = 46
0x000A  | 04     | 70      | STA 0x70     ; Store Fahrenheit (should be ~77°F)
0x000C  | 00     |         | NOP          ; Halt
*/

// ============================================================
// Program 10: Array Sum
// Sums an array of 4 bytes stored in memory
// ============================================================
/*
Address | Opcode | Operand | Description
--------|--------|---------|-------------
0x0000  | 01     | 00      | LDA #0       ; Initialize sum to 0
0x0002  | 04     | A0      | STA 0xA0     ; sum = 0
0x0004  | 06     | 00      | LDX #0       ; i = 0
0x0006  | 06     | 04      | LDX #4       ; count = 4
0x0008  | 30     | 04      | CPX #4       ; Check if done
0x000A  | 41     | 14      | BNE loop     ; Continue if i < count
0x000C  | 04     | A1      | STA 0xA1     ; Store final sum
0x000E  | 00     |         | NOP          ; Halt
0x0010  | 02     | B0      | LDA 0xB0     ; Load array[i]
0x0012  | 02     | A0      | LDX 0xA0     ; Load sum
0x0014  | 10     |         | ADD          ; sum += array[i]
0x0015  | 04     | A0      | STA 0xA0     ; Store sum
0x0017  | 16     |         | INC          ; i++
0x0018  | 48     | F4      | BRA loop     ; Loop
*/

// Array data at 0x00B0
/*
0x00B0  | 0A     |         | 10          ; array[0]
0x00B1  | 14     |         | 20          ; array[1]
0x00B2  | 1E     |         | 30          ; array[2]
0x00B3  | 28     |         | 40          ; array[3]
*/

// ============================================================
// Machine Code Translation Table
// ============================================================
/*
Mnemonic    | Opcode | Operands
------------|--------|----------
NOP         | 00     | None
LDA #imm    | 01     | 8-bit immediate
LDA dir     | 02     | 8-bit address
STA dir     | 04     | 8-bit address
LDX #imm    | 06     | 8-bit immediate
LDX dir     | 07     | 8-bit address
STX dir     | 08     | 8-bit address
LDY #imm    | 09     | 8-bit immediate
LDY dir     | 0A     | 8-bit address
STY dir     | 0B     | 8-bit address
ADD #imm    | 10     | 8-bit immediate
ADD dir     | 11     | 8-bit address
SUB #imm    | 12     | 8-bit immediate
SUB dir     | 13     | 8-bit address
MUL         | 14     | None
DIV         | 15     | None
INC         | 16     | None
DEC         | 17     | None
ADC         | 18     | None
SBC         | 19     | None
AND #imm    | 20     | 8-bit immediate
AND dir     | 21     | 8-bit address
OR #imm     | 22     | 8-bit immediate
OR dir      | 23     | 8-bit address
XOR #imm    | 24     | 8-bit immediate
XOR dir     | 25     | 8-bit address
NOT         | 26     | None
CLR         | 27     | None
SHL         | 28     | None
SHR         | 29     | None
ROL         | 2A     | None
ROR         | 2B     | None
SHL dir     | 2C     | 8-bit address
SHR dir     | 2D     | 8-bit address
CMP #imm    | 30     | 8-bit immediate
CMP dir     | 31     | 8-bit address
CPX #imm    | 32     | 8-bit immediate
CPY #imm    | 33     | 8-bit immediate
TST         | 34     | 8-bit address
BEQ         | 40     | 8-bit offset
BNE         | 41     | 8-bit offset
BMI         | 42     | 8-bit offset
BPL         | 43     | 8-bit offset
BVS         | 44     | 8-bit offset
BVC         | 45     | 8-bit offset
BCS         | 46     | 8-bit offset
BCC         | 47     | 8-bit offset
BRA         | 48     | 8-bit offset
JMP dir     | 50     | 16-bit address
JMP ind     | 51     | 16-bit address
JSR         | 52     | 16-bit address
RTS         | 53     | None
PHA         | 60     | None
PLA         | 61     | None
PHX         | 62     | None
PLX         | 63     | None
PHY         | 64     | None
PLY         | 65     | None
PHP         | 66     | None
PLP         | 67     | None
SQRT        | 70     | None
SQUARE      | 71     | None
ABS         | 72     | None
NEG         | 73     | None
EXP         | 74     | None
LOG         | 75     | None
SIN         | 76     | None
COS         | 77     | None
TAN         | 78     | None
POW         | 79     | None
*/
