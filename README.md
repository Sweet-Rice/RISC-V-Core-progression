## Overview

This repo follows a 32-bit RISC-V processor (RV32I). Started from building small hardware modules until I discovered HDLBits, then just moved there and focused this repo specifically for the core. 

 The current top level design has a clock rate of 100 MHz and moves sequentially through the traditional IF, ID, EX, MEM, WB phase cycle. It's currently a pure Harvard memory architecture, and has UART which is memory mapped into the load-store address space. Harvard was chosen to be close to the ultimate goal of a GPU, with plans to pivot to a modified Harvard architecture with a unified memory but separate buses.  
 
 (Do note that the multi phase terminology is sending one instruction per phase-cycle, this is not pipelined yet)

  There's a small firmware(?) that prints "Hello World!" in a loop, while polling to ensure characters get written to the terminal. UART is not stalling the core, the program is written explicitly to wait until characters are successfully written. 

   It currently synthesizes, places, routes, and generates a bitstream for Digilent's Arty A7 100T.

  ## Organization
  The repo is organized by "stages", albeit a little messy. Starts off with my beginner work, but quickly just shifts to the core modules. Within the stages is a readme that describes details of my process and the module.


   This was incredibly fun to make and was a good way to spend some sleepless nights. I've learned a lot about Computer Organization, Digital Logic, and Computer Architecture through this, and I really want to pursue what's next.


## Future Goals
   The ultimate goal of this repo is to release a GPU using an ISA based on RISC-V ISA. Until I get there, I need to pipeline, then multithread, then get a dumb GPU live.


## Measurements
### Timing summary

| Metric | Result |
|---|---:|
| Constraint | `100.000 MHz` / `10.000 ns` |
| Worst setup slack (WNS) | **+0.491 ns** |
| Total setup slack (TNS) | `0.000 ns` |
| Setup failing endpoints | `0 / 1840` |
| Worst hold slack (WHS) | **+0.078 ns** |
| Total hold slack (THS) | `0.000 ns` |
| Hold failing endpoints | `0 / 1840` |
| Pulse-width slack (WPWS) | `+3.750 ns` |
| Timing constraints | **Met** |

### Utilization summary

| Resource | Used | Available | Utilization |
|---|---:|---:|---:|
| Slice LUTs | 622 | 63,400 | 0.98% |
| LUTs as logic | 534 | 63,400 | 0.84% |
| LUTs as distributed memory | 88 | 19,000 | 0.46% |
| Slice registers | 472 | 126,800 | 0.37% |
| Block RAM tiles | 8 | 135 | 5.93% |
| DSP slices | 0 | 240 | 0.00% |
| Bonded I/O | 4 | 210 | 1.90% |
| BUFGCTRL | 1 | 32 | 3.13% |

 My favorite bit is the difference between single and multicycle. Single was implemented via just shoving everything into the decoder, and multicycle actually took a few hours at the whiteboard, some extraneous research, and a little more planning.
### Single-cycle versus multicycle
 | Metric | Earlier single-cycle experiment | Current multicycle core |
|---|---:|---:|
| Timing constraint | 20 ns | 10 ns |
| WNS | −0.305 ns | **+0.491 ns** |
| Failing setup endpoints | 8 / 694 | **0 / 1840** |
| Data-path delay | 13.238 ns | **9.550 ns** |
| Slice LUTs | 938 | **622** |
| Registers | 63 | 472 |
| Block RAM tiles | 4 | 8 |

## Limitations
 I have not put her through any official RV32I compliance suites yet, so undocumented limited functionality should be expected. A bitstream is provided specifically for the XC7A100tCSG324-1.
