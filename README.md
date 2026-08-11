# Incremental RV32I CPU in SystemVerilog

An incremental implementation of a RISC-V RV32I CPU, built one stage at a
time in SystemVerilog.

The project targets the Digilent Arty A7-100T. Simulation and synthesis are
performed through the Vivado GUI using Vivado's built-in simulator.

## Stages

| Stage | Topic | Execution | Status |
|---|---|---|---|
| [01 - Blink](stages/01-blink/) | Clocked logic, counters, and reset | Simulation and Arty A7-100T | Done |
| [02 - Mux](stages/02-4_1mux/) | Combinational logic, multiplexer | Simulation | Done |

## Repository Layout

- `rtl/` contains reusable synthesizable modules shared by later stages.
- `stages/` contains each incremental design, its testbench, and its documentation.
- Hardware stages include a stage-specific `.xdc` constraints file.
- `docs/images/` contains waveform and utilization screenshots.

Each stage has its own top module and exposes only the ports used by that stage.
