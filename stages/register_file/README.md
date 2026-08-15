# Stage 2 — Register File

## References

- **UG901** — RAM inference
- **UG474** — Slice anatomy
- **UG953** — Primitives

## Approach

Genuinely took an embarassing amount of time to fully understand memory. Scouring through the docs and googling. A lot of googling. And consulting AI. But I understand it now.

I approached this design at first after watching computer architecture and digital logic reference videos, including tri-state buffers, matrix addressing, and gated latch usage. Looking into all of these for the Arty proved that none of these were optimal (or possible, in the case of the tri-state buffer). I discovered LUT RAM primitives, which was mildly disappointing because I did want to try these other tricks. But, after quite a bit of reading, LUT RAM seems very well thought out and mirrored my intended usecase.

So, we will not be wasting any time trying to implement something that synthesizes well. Looking through the docs, we are targetting RAM64M. Implementing my own register system will be a waste of time. Trying to implement several muxes, a decoder, and flip-flop memory individually likely won't synthesize well. RAM64 being a primitive that only uses 4 LUTs serves as proof of good synthesis compression.

## Why RAM64M

We are targetting RAM64M for several reasons. The end goal of this project is to prepare to build a GPU. RAM64M (the one we are targetting) is 64 x 1Q, meaning 64 locations deep and 1 wide with 4 ports. Because we have 64 depth, each of these four ports has a 6 bit wide address bus, which allots an extra set of registers. In the future, this will give me leverage for 2 threads on the CPU.

More importantly, RISC-V docs have instructions that specify rs1, rs2, and rd. Simultaneous operations on rs1 and rs2 improves cycle speed and RAM64M's port count is quite helpful here.

## Verification

As this is heavily primitive based, at the current moment I don't see much value in rigorous testing, as this alone will not meaningfully improve or worsen the critical path or area.

Regardless, a testbench will be done alongside timing and utilization reports.

```
run all
=== 802 checks, 0 errors ===
PASS
```

## Synthesis

At first, synthesis showed I had 132 LUTs, which didn't make sense. Referencing UG474, the calculation is a lot simpler for quad port since all prerequisites are met besides bit width, and its just 32 instances to reach the 32 bit width. So 128 LUTs. Could I beat Vivado?

Checking my outputs, I had an unused `d_out3`. Cutting that out shaved the LUT count by 44. What?

Under Out-Of-Context Synthesis, this design produces 88 Slice LUTs, more specifically RAMD64E. So, curiously, it did not synthesize to what I wanted. I was targetting 4 port wide RAM64M, 64 x 1Q, but instead seem to have gotten 3 bit wide 2 port wide. Vivado seems to have chosen 64 x 3SDP RAM64M.

Referencing UG474, RAM64M SDP mode has 3 location width, so to reach 32 bit width Vivado seems to have instantiated 11 times in parallel. And since only 1 read port exists per SDP, to reach 2 it doubled up, making 22. Taking into account that RAM64M is made of 4 RAMD64E, that makes 88 LUTs, which tracks with our numbers. Vivado beat me again. Mildly frustrating.

In the future, if I ever need to use that third input and output bus for whatever reason, I will likely instantiate quad mode and save the 4 LUTs compared to SDP. It seems quad only becomes worthwhile after 3 or more ports are required in the design.

## Timing

Regardless, I got a WNS of +5.93 ns from an 8 ns constraint, so optimizing the speed of this is absolutely not a priority.