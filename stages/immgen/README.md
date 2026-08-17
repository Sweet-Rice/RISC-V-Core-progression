# Stage 3 — Immediate Generator

Target: Arty A7 (Artix-7), Vivado, RV32I

Files: `immgen.sv`, `immgen_tb.sv`

## References

- **RISC-V Unprivileged ISA Manual** — 2.2 base formats, 2.3 immediate encoding variants, 2.5 control transfer, Ch. 36 instruction listings
- **UG474** — LUT6/LUT5 fracturing, MUXF7
- **DS181** — Switching characteristics

## Approach

This one was hard because of the encoding, and the encoding is the most arbitrary thing I have read in this entire project. You cannot derive it. You just have to read it, and trying to understand how to read it is excruciating.

I spent an absurd amount of time trying to find the optimal structure by staring at the format figures before writing anything. 

The other thing that cost me hours: the spec draws the same information twice in opposite directions. 2.2 and 2.3 put instruction bit positions on the ruler and immediate bit positions in the boxes. Figure 2.4 does the reverse. I read them together without noticing and produced an entire page of notes with the indices backwards and then I had to throw it out. 

## Why there is no arithmetic here

Once the indices were straight things got pretty simple? There's no math in an immediate generator. Every output bit is an instruction bit routed somewhere else, a constant zero, or `inst[31]` repeated for sign extension.

RISC-V is beautifully written. The sign bit is pinned at `inst[31]` in every format specifically to speed up sign extension, and the register specifiers sit at constant positions in every format even though it means scattering the immediate bits around them. The ugly scrambled immediate encoding is the price, but I think I'd also pay that given the opportunity. 

Two things fall out of it that I exploited:

- `imm[31]` is `inst[31]` in all five formats. It's a wire. Costs nothing.
- `imm[30:20]` is `inst[31]` in four of five formats. One select signal, eleven bits, no per-format mux.

The U-format "shift left by 12" is also free. It's not a shifter. the field is wired 12 positions over and the bottom is tied to ground. Thank god for the ingenuity of the RV architects.

## Structure

Defaults first, then a `unique if` chain overrides per format:

```
imm[31:11] = {21{inst[31]}}   // sign extension
imm[10:5]  = inst[30:25]      // shared by I, S, B, J
imm[4:1]   = inst[24:21]      // I, J
imm[0]     = inst[20]         // I
```

The count that actually predicts LUT cost is distinct sources per output bit:

| bits | sources | note |
|---|---|---|
| `imm[31]` | 1 | wire, free |
| `imm[30:20]` | 2 | sign-ext vs U |
| `imm[19:12]` | 2 | sign-ext vs U/J |
| `imm[11]` | 4 | widest bit in the module |
| `imm[10:5]` | 2 | shared vs U zero |
| `imm[4:1]` | 3 | I/J vs S/B vs U |
| `imm[0]` | 3 | I vs S vs zero |

31 of 32 bits need logic. The worst is `imm[11]` at 4 sources plus 2 select bits, which is 6 inputs, which is exactly one LUT6. That's why no MUXF7 shows up anywhere in this design.

### Format selection

| Selector | Matches | Format |
|---|---|---|
| `inst[5:0] == 6'b100011` | STORE `0100011`, BRANCH `1100011` | S / B |
| ↳ `inst[6:4] == 3'b110` | BRANCH | B |
| `inst[4:2] == 3'b101` | LUI `0110111`, AUIPC `0010111` | U |
| `inst[5:3] == 3'b101` | JAL `1101111` | J |
| else | LOAD, OP-IMM, JALR, MISC-MEM, SYSTEM | I |

I originally used `inst[3:2] == 2'b11` for the J arm. MISC-MEM (`0001111`) also matches that, so FENCE would have been handed the J-format permutation. Moved to `inst[5:3]`, which JAL alone matches, and FENCE falls back into the I arm where its shape belongs.

R-format falls through to I. Its immediate is a don't-care and the control unit gates the write, so I'm not spending a mux arm on it.

## Verification

Randomize `inst[31:6]`, pick one of the ten immediate-bearing opcodes, compare against an expected value built from five flat concatenations read straight off the format shapes on p. 585. The point of building the expected values as flat concatenations is that my DUT builds them as bit-groups with priority overrides. Goal here is to hardcode a true evaluation concatenation and compare against that to make sure my wiring is consistent, making sure to separate my hdl logic with my eval logic.

R is deliberately not in the loop.

```
run all
=== 2000 checks, 0 errors ===
PASS
```

## Synthesis

Out-of-context, `set_max_delay -datapath_only` at 8 ns, same as Stages 1 and 2.

| | |
|---|---|
| LUT6 | 18 |
| LUT5 | 15 |
| LUT3 | 3 |
| **Total primitives** | **36** |
| **Slice LUTs** | **34** |
| Flip-flops | 0 |

I predicted 35. Got 36 primitives in 34 slice LUTs. Closest I have been in three stages, and the first time my model was right for the right reason instead of by luck.

The gap between 36 and 34 is fracturing. two physical LUT6s each hosting two LUT5s. What's interesting is how little of it happened. Fifteen LUT5s and only two pairs fractured, because both halves have to share the same five inputs to sit in one site. Most of my 2:1 muxes share a select but take different data: `imm[30]` picks between `inst[30]` and `inst[31]`, `imm[29]` picks between `inst[29]` and `inst[31]`. Same structure, different input sets, can't pair. Vivado found the only two that could.

## Timing

| | |
|---|---|
| WNS | +4.795 ns @ 8 ns |
| Data path | 3.205 ns |
| Logic | 0.248 ns (7.7%) |
| Route | 2.957 ns (92.3%) |
| Logic levels | 2 (LUT6 → LUT5) |
| MUXF7 / MUXF8 | none |

Critical path is `inst[1]` → `imm[10]`, one LUT6 into one LUT5, 0.124 ns each. The net between them has `fo=31` — that's the shared select term feeding 31 output bits, and it's the reason routing dominates.

I called 2 logic levels and no MUXF7, both correct. I called 5 ns total and it came in at 3.205 ns, with logic guessed at 1 ns against an actual 0.248 ns. So the structural model held and the delay model was about 40% heavy. Worth remembering that I overestimate LUT delay.

At 92% routing this thing is completely route-bound, which is a different world from the Stage 1 ALU at ~5.9 ns through a carry chain. Two of the three routing hops are `fo=0` port nets at 0.973 ns each, which are OOC estimates and will move after place-and-route.

Nothing here is worth optimizing. At 3.2 ns against an 8 ns budget this module will never be the stage that sets my clock.

## Open items

- **Format-select ownership.** Decode is internal right now. The Stage 4 decoder is going to decode `inst[6:2]` anyway for the ALU op, register write enable, and memory control, so this is duplicated logic. Whether it moves depends on where the pipeline boundaries land, which I haven't decided.
- **FENCE, ECALL/EBREAK, CSR.** These are I-shaped but what sits in `inst[31:20]` isn't a sign-extended number. I don't understand their behavior well enough yet to say what the right output is. Revisit when SYSTEM gets implemented.
- **x0 write suppression** is still homeless, carried over from Stage 2. It belongs to the decoder.

## Takeaways
 I really, really hated writing this. This was the most tedious thing I have ever spent my time on.
Cross referencing the docs, looking back and forth, trying to make sense of it all and find an optimal path, 
just awful. But I learned a few things, and I think I finally stopped looking at muxes like conditional branches.
This definitely gave me a bigger appreciation for the geniuses that wrote the arch.

 I think that I'm probably not going to revisit this for optimization. If I do, it's to reduce a critical path
to squeeze this into a particular stage of a pipeline. The only change is to reduce the depth stages and make all the
necessary muxes completely parallel. Eventually, reduce fanout. I anticipate having to nuke the entire system and logic here
if condensing for pipelining needs to happen, and I'll just recycle opcode decoding from the decoder and pass that as a signal to the immgen instead, so it'll cost a few input wires but ultimately shave off a good chunk of time.


 Also, no waveform here. That would be stupid.