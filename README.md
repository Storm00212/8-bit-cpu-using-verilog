# 8-Bit CPU in Verilog

A complete, functional 8-bit CPU implementation in Verilog HDL with arithmetic, logical, scientific calculation capabilities, RAM, ROM, and comprehensive instruction set.

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [File Structure](#file-structure)
- [Instruction Set](#instruction-set)
- [Getting Started](#getting-started)
- [Simulation](#simulation)
- [Synthesis](#synthesis)
- [Example Programs](#example-programs)
- [Performance](#performance)

---

## ✨ Features

### Arithmetic Operations
- **Addition** (ADD) - 8-bit addition with carry flag
- **Subtraction** (SUB) - 8-bit subtraction with borrow flag
- **Multiplication** (MUL) - 8-bit × 8-bit = 8-bit multiplication
- **Division** (DIV) - 8-bit ÷ 8-bit division with quotient
- **Increment/Decrement** (INC/DEC) - Single operand operations

### Logical Operations
- **AND** - Bitwise AND
- **OR** - Bitwise OR
- **XOR** - Bitwise XOR
- **NOT** - Bitwise NOT (complement)

### Shift/Rotate Operations
- **Shift Left** (SHL) - Logical shift left
- **Shift Right** (SHR) - Logical shift right
- **Rotate Left** (ROL) - Rotate left through carry
- **Rotate Right** (ROR) - Rotate right through carry

### Scientific Calculations
- **Square Root** (SQRT) - Integer square root approximation
- **Square** (SQUARE) - x² calculation
- **Absolute Value** (ABS) - |x|
- **Negate** (NEG) - Two's complement negation
- **Exponential** (EXP) - e^x approximation
- **Natural Log** (LOG) - ln(x) approximation
- **Trigonometric** (SIN, COS, TAN) - Angle functions

### Memory Operations
- **Load/Store** - Register to memory transfers
- **Direct Addressing** - 8-bit addresses
- **Immediate** - Literal values
- **Stack Operations** - PUSH, PULL, PHA, PLA, PHX, PLX, PHY, PLY

### Control Flow
- **Branching** - Conditional jumps (BEQ, BNE, BMI, BPL, BCS, BCC, BVS, BVC)
- **Unconditional Branch** (BRA)
- **Jump** (JMP) - Direct and indirect
- **Subroutine** (JSR, RTS) - Call and return

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        CPU TOP LEVEL                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │   Control   │◄──►│    ALU      │◄──►│   Register  │    │
│  │    Unit     │    │             │    │    File     │    │
│  └──────┬──────┘    └─────────────┘    └──────┬──────┘    │
│         │                                      │           │
│         │      ┌─────────────┐                 │           │
│         └─────►│ Instruction │                 │           │
│                │    Decode    │                 │           │
│                └─────────────┘                 │           │
│                                               │           │
│  ┌────────────────────────────────────────────┴──────────┐ │
│  │              16-bit Address Bus                         │ │
│  │              8-bit Data Bus                              │ │
│  └─────────────────────────────────────────────────────────┘ │
│         │                          │                        │
│         ▼                          ▼                        │
│  ┌─────────────┐            ┌─────────────┐                │
│  │     ROM     │            │     RAM     │                │
│  │  (Program)  │            │   (Data)    │                │
│  └─────────────┘            └─────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

### Components

| Component | Description |
|-----------|-------------|
| **Control Unit** | Decodes instructions, generates control signals |
| **ALU** | Performs all arithmetic and logical operations |
| **Register File** | Stores CPU state (ACC, X, Y, PC, SP, IR, Flags) |
| **ROM** | 64KB program memory |
| **RAM** | 64KB data memory |

### Registers

| Register | Size | Purpose |
|----------|------|---------|
| **ACC** | 8-bit | Accumulator - primary arithmetic register |
| **X** | 8-bit | Index register 1 |
| **Y** | 8-bit | Index register 2 |
| **PC** | 16-bit | Program Counter - instruction pointer |
| **SP** | 8-bit | Stack Pointer - stack position |
| **IR** | 8-bit | Instruction Register - current opcode |
| **FLAGS** | 8-bit | Status flags (C, Z, N, V, etc.) |

### Flags

| Bit | Name | Description |
|-----|------|-------------|
| 0 | C | Carry flag (arithmetic overflow) |
| 1 | Z | Zero flag (result is zero) |
| 2 | N | Negative flag (result is negative) |
| 3 | V | Overflow flag (signed overflow) |
| 4 | I | Interrupt Disable |
| 5 | D | Decimal Mode |
| 6 | B | Break Flag |
| 7 | X | Extended Flag |

---

## 📁 File Structure

```
8-bit-cpu-using-verilog/
├── instructions.vh      # Opcode and instruction definitions
├── alu.v               # Arithmetic Logic Unit
├── register_file.v     # CPU registers
├── ram.v               # Random Access Memory (64KB)
├── rom.v               # Read Only Memory (64KB)
├── control_unit.v      # Instruction decoder and FSM
├── cpu_top.v           # Top-level CPU module
├── cpu_tb.v            # Testbench for simulation
├── example_programs.vh # Example assembly programs
└── README.md           # This file
```

---

## 📖 Instruction Set

### Load/Store Instructions

| Mnemonic | Opcode | Operation | Flags |
|----------|--------|-----------|-------|
| `LDA #imm` | 01 | Load Accumulator Immediate | Z, N |
| `LDA dir` | 02 | Load Accumulator Direct | Z, N |
| `STA dir` | 04 | Store Accumulator Direct | - |
| `LDX #imm` | 06 | Load X Immediate | Z, N |
| `LDX dir` | 07 | Load X Direct | Z, N |
| `STX dir` | 08 | Store X Direct | - |
| `LDY #imm` | 09 | Load Y Immediate | Z, N |
| `LDY dir` | 0A | Load Y Direct | Z, N |
| `STY dir` | 0B | Store Y Direct | - |

### Arithmetic Instructions

| Mnemonic | Opcode | Operation | Flags |
|----------|--------|-----------|-------|
| `ADD #imm` | 10 | Add Immediate | C, Z, N, V |
| `ADD dir` | 11 | Add Direct | C, Z, N, V |
| `SUB #imm` | 12 | Subtract Immediate | C, Z, N, V |
| `SUB dir` | 13 | Subtract Direct | C, Z, N, V |
| `MUL` | 14 | Multiply (ACC × X) | Z, N |
| `DIV` | 15 | Divide (ACC ÷ X) | Z, N |
| `INC` | 16 | Increment ACC | Z, N, V |
| `DEC` | 17 | Decrement ACC | Z, N, V |
| `ADC` | 18 | Add with Carry | C, Z, N, V |
| `SBC` | 19 | Subtract with Borrow | C, Z, N, V |

### Logical Instructions

| Mnemonic | Opcode | Operation | Flags |
|----------|--------|-----------|-------|
| `AND #imm` | 20 | AND Immediate | Z, N |
| `AND dir` | 21 | AND Direct | Z, N |
| `OR #imm` | 22 | OR Immediate | Z, N |
| `OR dir` | 23 | OR Direct | Z, N |
| `XOR #imm` | 24 | XOR Immediate | Z, N |
| `XOR dir` | 25 | XOR Direct | Z, N |
| `NOT` | 26 | NOT Accumulator | Z, N |
| `CLR` | 27 | Clear Accumulator | Z |

### Shift/Rotate Instructions

| Mnemonic | Opcode | Operation | Flags |
|----------|--------|-----------|-------|
| `SHL` | 28 | Shift Left | C, Z, N |
| `SHR` | 29 | Shift Right | C, Z, N |
| `ROL` | 2A | Rotate Left | C, Z, N |
| `ROR` | 2B | Rotate Right | C, Z, N |

### Compare Instructions

| Mnemonic | Opcode | Operation | Flags |
|----------|--------|-----------|-------|
| `CMP #imm` | 30 | Compare ACC with Immediate | C, Z, N, V |
| `CMP dir` | 31 | Compare ACC with Memory | C, Z, N, V |
| `CPX #imm` | 32 | Compare X with Immediate | Z, N |
| `CPY #imm` | 33 | Compare Y with Immediate | Z, N |

### Branch Instructions

| Mnemonic | Opcode | Condition |
|----------|--------|-----------|
| `BEQ` | 40 | Branch if Equal (Z=1) |
| `BNE` | 41 | Branch if Not Equal (Z=0) |
| `BMI` | 42 | Branch if Minus (N=1) |
| `BPL` | 43 | Branch if Plus (N=0) |
| `BVS` | 44 | Branch if Overflow (V=1) |
| `BVC` | 45 | Branch if No Overflow (V=0) |
| `BCS` | 46 | Branch if Carry Set (C=1) |
| `BCC` | 47 | Branch if Carry Clear (C=0) |
| `BRA` | 48 | Branch Always |

### Jump Instructions

| Mnemonic | Opcode | Operation |
|----------|--------|-----------|
| `JMP dir` | 50 | Jump Direct |
| `JMP ind` | 51 | Jump Indirect |
| `JSR` | 52 | Jump to Subroutine |
| `RTS` | 53 | Return from Subroutine |

### Stack Instructions

| Mnemonic | Opcode | Operation |
|----------|--------|-----------|
| `PHA` | 60 | Push Accumulator |
| `PLA` | 61 | Pull Accumulator |
| `PHX` | 62 | Push X Register |
| `PLX` | 63 | Pull X Register |
| `PHY` | 64 | Push Y Register |
| `PLY` | 65 | Pull Y Register |
| `PHP` | 66 | Push Processor Status |
| `PLP` | 67 | Pull Processor Status |

### Scientific Instructions

| Mnemonic | Opcode | Operation | Flags |
|----------|--------|-----------|-------|
| `SQRT` | 70 | Square Root | Z, N |
| `SQUARE` | 71 | Square (x²) | Z, N |
| `ABS` | 72 | Absolute Value | Z, N |
| `NEG` | 73 | Negate | Z, N |
| `EXP` | 74 | Exponential (e^x) | Z, N |
| `LOG` | 75 | Natural Log | Z, N |
| `SIN` | 76 | Sine | Z, N |
| `COS` | 77 | Cosine | Z, N |
| `TAN` | 78 | Tangent | Z, N |
| `POW` | 79 | Power (ACC^X) | Z, N |

### Other Instructions

| Mnemonic | Opcode | Operation |
|----------|--------|-----------|
| `NOP` | 00 | No Operation |
| `TST` | 34 | Test Bits |

---

## 🚀 Getting Started

### Prerequisites

- Verilog HDL simulator (ModelSim, Icarus Verilog, Vivado, etc.)
- Basic knowledge of Verilog and digital logic

### Running Simulations

#### Using Icarus Verilog (free):

```bash
# Compile the CPU and testbench
iverilog -o cpu_sim cpu_top.v alu.v control_unit.v register_file.v ram.v rom.v cpu_tb.v

# Run the simulation
vvp cpu_sim

# View waveforms (optional)
gtkwave cpu_sim.vcd
```

#### Using ModelSim:

```tcl
# In ModelSim console
vcom -work work cpu_top.v alu.v control_unit.v register_file.v ram.v rom.v cpu_tb.v
vsim work.cpu_tb
run -all
```

#### Using Vivado:

1. Create a new project
2. Add all .v files
3. Set cpu_tb as top module for simulation
4. Run behavioral simulation

---

## 🧪 Testing

### Testbench Coverage

The testbench (`cpu_tb.v`) includes tests for:

1. ✅ Reset functionality
2. ✅ Load/Store operations
3. ✅ Addition/Subtraction
4. ✅ Logical operations (AND, OR, XOR, NOT)
5. ✅ Increment/Decrement
6. ✅ Register loads (X, Y)
7. ✅ Memory operations
8. ✅ Branch operations

### Running Specific Tests

Modify the testbench to enable/disable specific tests:

```verilog
// Enable/disable tests by commenting/uncommenting
// test_reset;
// test_addition(10, 5, 15);
// test_subtraction(10, 3, 7);
```

---

## 📊 Performance

### Clock Frequency

The CPU is designed for synchronous operation with a single clock domain. Maximum frequency depends on the target technology:

| Technology | Estimated Max Frequency |
|------------|------------------------|
| FPGA (Spartan-6) | 100-200 MHz |
| FPGA (Artix-7) | 200-400 MHz |
| ASIC (130nm) | 300-500 MHz |
| ASIC (65nm) | 500 MHz+ |

### Instruction Timing

| Instruction Type | Cycles |
|-----------------|--------|
| NOP | 1 |
| Load/Store | 2-3 |
| ALU (simple) | 1 |
| ALU (mul/div) | 8+ |
| Branch | 2 |
| Jump | 2 |
| Scientific | Variable |

---

## 🔬 Example Programs

### Program 1: Basic Calculator

```verilog
// Calculate: (10 × 5) + 2 - 10 = 42
LDA #10      // Load 10
LDX #5       // Load 5
MUL          // 10 × 5 = 50
ADD #2       // 50 + 2 = 52
SUB #10      // 52 - 10 = 42
STA 0x20     // Store result
NOP          // Halt
```

### Program 2: Fibonacci Sequence

```verilog
// Generate first 8 Fibonacci numbers
LDA #0       // F0 = 0
STA 0x80     // Store at 0x0080
LDA #1       // F1 = 1
STA 0x81     // Store at 0x0081
LDX #2       // i = 2
LDY #8       // count = 8
// Loop...
```

### Program 3: Temperature Conversion

```verilog
// Convert 25°C to Fahrenheit: F = (25 × 9/5) + 32 = 77°F
LDA #25      // Load Celsius
MUL          // Multiply by X (should be 9)
ADD #5       // Adjust for 9/5
DIV          // Divide by 5
ADD #32      // Add 32
STA 0x70     // Store Fahrenheit
NOP          // Halt
```

---

## 🔧 Customization

### Modifying Instruction Set

Edit `instructions.vh` to add or modify opcodes:

```verilog
// Add new opcode
`define OPCODE_MY_OP  8'hXX  // Your custom operation

// Then implement in control_unit.v and alu.v
```

### Changing Memory Sizes

Edit `instructions.vh`:

```verilog
`define RAM_SIZE   16'hXXXX  // New RAM size
`define ROM_SIZE   16'hXXXX  // New ROM size
```

### Adding New Instructions

1. Define opcode in `instructions.vh`
2. Add FSM state in `control_unit.v`
3. Add ALU operation in `alu.v`
4. Add test case in `cpu_tb.v`

---

## 📝 Technical Notes

### Address Space

```
0x0000 - 0x00FF  │  ROM (Program Memory)
0x0100 - 0x01FF  │  Stack
0x0200 - 0xFFFF  │  RAM (Data Memory)
```

### Bus Widths

| Bus | Width | Description |
|-----|-------|-------------|
| Data Bus | 8-bit | Bidirectional data transfer |
| Address Bus | 16-bit | Memory addressing (64KB) |
| Control | Multiple | Read, Write, Clock, Reset |

### Reset Behavior

On reset:
- PC = 0x0000
- ACC = 0x00
- X = 0x00
- Y = 0x00
- SP = 0xFF
- Flags = 0x00

---

## 📚 References

- [Verilog HDL Documentation](https://www.verilog.com/)
- [Digital Design Fundamentals](https://en.wikipedia.org/wiki/Digital_electronics)
- [CPU Design Principles](https://en.wikipedia.org/wiki/Central_processing_unit)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

---

## 📄 License

This project is open source and available under the MIT License.

---

## 👤 Author

Created for educational purposes to demonstrate CPU architecture and Verilog HDL programming.

---

**Happy Computing!** 🖥️
