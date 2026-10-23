# Mixed-Precision MAC Verification Plan

## 1. Scope

The current DUT is `rtl/mixed_precision_mac.sv`. It implements one signed
multiply-accumulate datapath with INT4/INT8 operand selection and a signed
32-bit accumulator. This plan verifies that block; it does **not** claim that
a full CNN accelerator, DMA engine, SRAM subsystem, or layer controller exists.

## 2. Interface contract

| Signal | Meaning |
|---|---|
| `clk` | Rising-edge clock |
| `rst_n` | Active-low asynchronous reset |
| `enable` | Accumulate when high and no clear is requested |
| `clear_acc` | Synchronous accumulator clear; takes priority over enable |
| `precision_mode` | 0 = signed INT4 low nibble; 1 = signed INT8 full byte |
| `activation`, `weight` | Signed 8-bit input ports |
| `accumulator` | Signed 32-bit accumulated output |

INT4 mode sign-extends bits [3:0] of each input. INT8 mode uses all eight
input bits. The expected accumulator behavior is reset > clear > enable > hold.
The reference model wraps accumulation to signed 32-bit two's-complement
arithmetic, matching the intended RTL bit width.

## 3. Verification layers

1. **Directed tests:** reset, INT4/INT8 boundaries, clear/enable priority,
   hold behavior, repeated accumulation, and accumulator wraparound.
2. **Independent reference model:** Python bit-accurate model with unit tests.
3. **UVM constrained-random:** randomized operands, precision, enable, and
   clear; reproducible seed and self-checking scoreboard.
4. **Assertions:** reset/clear/hold invariants and any additional properties
   supported by the chosen simulator.
5. **Functional coverage:** precision x enable x clear; operand sign classes;
   boundary values; and cross coverage of precision with operand classes.
6. **Mutation testing:** introduce controlled temporary RTL bugs and confirm
   the testbench detects them; never leave mutants in the main design.
7. **Regression:** save simulator version, seed, pass/fail status, logs, and
   coverage outputs for each run.

## 4. Test matrix

| ID | Scenario | Expected check |
|---|---|---|
| RST-01 | Assert active-low reset | Accumulator becomes zero |
| INT4-01 | 7 x 7 | Product +49 |
| INT4-02 | -8 x 1 | Product -8 |
| INT4-03 | -1 x -8 | Product +8 |
| INT4-04 | High input nibble changes, low nibble fixed | INT4 result unchanged |
| INT8-01 | 127 x 127 | Product +16129 |
| INT8-02 | -128 x 1 | Product -128 |
| INT8-03 | -128 x -128 | Product +16384 |
| CTRL-01 | Clear and enable both high | Clear wins |
| CTRL-02 | Enable low and clear low | Accumulator holds |
| ACC-01 | Multiple consecutive MACs | Sum matches reference |
| ACC-02 | Signed 32-bit overflow boundary | Defined wrap behavior matches RTL |
| RAND-01 | Constrained-random operations | Every observed result matches model |
| MUT-01 | Break INT4 sign extension | At least one test fails |
| MUT-02 | Reverse clear/enable priority | At least one test fails |

## 5. Completion criteria

- All directed tests pass on the unmodified DUT.
- The independent Python model's unit tests pass.
- UVM testbench compiles and runs on a simulator with compatible UVM support.
- No scoreboard mismatches in the recorded regression.
- Every planned functional-coverage bin is hit or has a documented exclusion.
- Coverage is reported as measured output, not inferred from test count.
- At least two deliberately injected RTL faults are detected.
- Reproduction commands and tool versions are documented.

## 6. Tool compatibility

The existing smoke test uses Icarus Verilog. Full class-based UVM normally
requires a simulator with suitable SystemVerilog/UVM support (for example,
Cadence Xcelium or Siemens Questa). Do not treat a UVM source file as tested
until it has actually compiled and run with the selected UVM library.

## 7. Future accelerator-level extension

After block-level verification closes, expand the DUT to a multi-MAC tile with
operand buffers and a controller. Then add transaction-level tests for tile
configuration, data loading, result ordering, stalls, reset during operation,
and end-to-end comparison against a Python/NumPy matrix reference.
