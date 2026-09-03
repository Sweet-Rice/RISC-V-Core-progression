# Multistage

I do have some pride in this one. This is basically the accumulation of all of my efforts to learn Digital Logic, Computer Organization, and Computer Architecture.

This was probably the most fun module out of all of them. Everything I had been doing up to this point finally clicked, and I got to watch all of the pieces come together like a puzzle. It was tedious and occasionally annoying, but fun nonetheless.

I will admit that I caved and lazily used an AI-generated testbench. In my defense, it was 4 AM, I was excited, I was exhausted, and it will be replaced soon. It's also extremely simple and mostly just scaffolding anyway.

---

# Architecture

This is a 5-stage (`IF`, `ID`, `EX`, `MEM`, `WB`) core. There is no pipelining just yet, but most of the infrastructure for it is already there.

For now, each stage executes sequentially under the control of a finite state machine. The FSM advances through the stages one at a time and remains in the current stage whenever the core stalls. There are also already some forwarding mechanisms in place, primarily for branching and jumping.

Every boundary between stages has its own set of registers. `IF/ID` has the ID registers, `ID/EX` has the EX registers, and so on.

This means values are explicitly registered before being passed into the next stage rather than having the entire datapath chained together combinationally. Besides making the design much easier to reason about, this decoupled the logic between stages and really helped me understand what was actually happening inside the core and how the different pieces should be organized.

Honestly, I kind of wish I had committed to a multistage design before the whole mess that happened in the standalone decoder, but I digress.

---

# Measurements

|                       | Single-Cycle       | Multicycle          |
| --------------------- | ------------------ | ------------------- |
| WNS                   | −0.305 ns @ 20 ns  | **+1.099 ns @ 10 ns** |
| Data Path             | 13.238 ns          | **8.765 ns**        |
| Logic Levels          | 20                 | **9**               |
| Failing Endpoints     | 8 / 694            | **0 / 1740**        |
| Slice LUTs            | 938                | **624**             |
| Flip-Flops            | 63                 | 438                 |
| Latches               | 0                  | 0                   |
| BRAM                   | 4                  | 7                   |

These results are extremely satisfying.

The single-cycle design still has the obvious CPI advantage of completing an instruction in one clock cycle, but the multicycle core has a dramatically shorter critical path and can sustain a much faster clock. Once pipelining is implemented and multiple instructions can occupy those stages simultaneously, this architecture should start looking very pretty.

I am very happy with this result.

There were a few synthesis problems along the way. Initially, BRAM and basically every module except `datapath` refused to synthesize because I had forgotten to drive several outputs.

After fixing that, the BRAMs still refused to instantiate because the memories were empty and Vivado optimized them away. I added a memory initialization file, and after that all but one of the intended BRAM instances synthesized correctly.