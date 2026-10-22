# Layer-Wise Mixed-Precision Neural Network Accelerator

A VLSI research project exploring selectable signed INT4/INT8 arithmetic for energy-efficient edge inference.

> **Implementation status:** The current RTL implements and verifies a mixed-precision multiply-accumulate (MAC) block. It is a building block for a future layer-wise neural-network accelerator, not a complete neural-network accelerator yet.

## Implemented RTL features

- Signed 8-bit activation and weight inputs.
- INT4 mode using each input's low nibble as signed 4-bit two's-complement data (−8 through +7).
- INT8 mode using complete signed 8-bit operands (−128 through +127).
- Signed multiplication and a 32-bit accumulator.
- Active-low reset, enable control, and synchronous accumulator clear.

| precision_mode | Operand interpretation |
|---|---|
| 0 | Signed INT4 values from the low four bits |
| 1 | Signed INT8 values from the full eight bits |

## Verification

The recorded Icarus Verilog simulation completed **11 passing checks**, covering reset, accumulator clearing, INT4 and INT8 arithmetic, signed edge cases, and accumulator hold when disabled.

Selected expected results: 7 × 7 = 49; 127 × 127 = 16129; −128 × 1 = −128; −128 × −128 = 16384.

## Run the simulation

Requirements: Icarus Verilog (`iverilog`, `vvp`). Run from the repository root:

```bash
mkdir -p results/simulation results/waveforms
iverilog -g2012 -Wall -s tb_mixed_precision_mac -o results/simulation/tb_mixed_precision_mac.vvp rtl/mixed_precision_mac.sv tb/tb_mixed_precision_mac.sv
vvp results/simulation/tb_mixed_precision_mac.vvp
```

Open the waveform with GTKWave using `gtkwave results/waveforms/mixed_precision_mac.vcd`.

## Synthesis and physical-design evaluation

Previously recorded OpenROAD results for the SKY130 HD platform:

| Metric | Reported value |
|---|---:|
| Final design area | approximately 5,992 µm² |
| Estimated total power | approximately 3.19 mW |
| Critical-path delay | approximately 8.80 ns |
| Worst slack | approximately +1.16 ns |
| Setup/hold violation counts in referenced summary | 0 / 0 |

These are flow-reported estimates, not measured silicon results. Power depends on switching-activity assumptions and constraints. An empty DRC report alone does not establish complete physical-verification sign-off.

## Intended repository structure

- `rtl/`: synthesizable SystemVerilog RTL
- `tb/`: RTL testbench
- `scripts/`: simulation/test scripts
- `model/`: reference model
- `constraints/`: timing constraints
- `results/simulation/`: compilation and simulation logs
- `results/waveforms/`: VCD trace, GTKWave session, and screenshot
- `results/ppa/`: selected synthesis and physical-design reports

## Future work

1. Compare INT4-only, INT8-only, and mixed-precision implementations.
2. Add explicit layer-wise precision control and integrate a neural-network datapath.
3. Evaluate inference accuracy on a specified model and dataset.
4. Use realistic switching activity for power estimation.
5. Compare area, timing, and energy under consistent constraints.
6. Expand directed and randomized verification.

## Tools

SystemVerilog · Icarus Verilog · GTKWave · Yosys · OpenROAD · SKY130 HD

Mixed-precision arithmetic is being investigated as a potential hardware optimization for edge inference. Any claimed improvement in accuracy, performance, power, or energy requires a defined baseline and reproducible measurements.
