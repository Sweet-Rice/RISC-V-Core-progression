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
| [03 - ALU](stages/alu/) | Opcode select, arithmetic, shifters | Simulation and synthesis | Done | 

## Repository Layout


- `stages/` contains each incremental design, its testbench, and its documentation.
- Hardware stages include a stage-specific `.xdc` constraints file.



