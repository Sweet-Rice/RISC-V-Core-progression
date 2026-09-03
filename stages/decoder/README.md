# Stage [?] - Post Game Analysis

I have... several gripes with this initial design.

The initial idea when writing this was to quickly churn out a working single cycle processor.

Turns out that was a bad idea, as it scaled incredibly badly.

Much of the logic I wrote out here ended up tightly coupling with one another, so I was missing a lot of the concepts I would have learned by separating them. This made creating a multi-stage solution much more difficult. For example, coupling the logic behind the "handshake" mechanism to stall the processor inside the decoder made it much harder to understand. Once I separated the two, it felt second nature.

I will be intentionally neglecting timing constraints and LUT counts for this design. This was mostly an educational tool, and it would be dishonest to have a report on this as little to no effort to optimize area/performance was made. Regardless, I will be documenting my architectural decisions.

---

# Architecture

Many of the features inside this were implemented at the time of necessity. As such, many of these designs are coupled to the requirements that the "decoder" (Which I say in quotes because this in reality is much more than decode).

We define a register and a memory write enable, as well as signals `mem_ready`, `stall`, and `mem_valid` to set up infrastructure for our memory stall handshake.

Our stall function is latched logic that leverages `stall`, `mem_valid` and `mem_ready` to basically just prevent `pc` from incrementing until we receive a `mem_ready` signal. Outside of stall, our `pc` increments and branches normally, based on signals ingested from other modules.

Outside of the stall function, nothing is very novel. The entire behavior of the CPU is basically gated behind one massive `case`, which honestly creates unnecessary coupling and (in theory) wastes LUTS.

---

# Measurements

## `alu_decoder`

| Metric       | Value                             |
| ------------ | --------------------------------- |
| Slice LUTs   | 5                                 |
| Primitives   | 6: 1×LUT2, 1×LUT4, 1×LUT5, 3×LUT6 |
| Logic levels | 2                                 |
| WNS          | +4.847 ns                         |
| Routing      | 92%                               |
| Path start   | `inst[3]`                         |

**Structure:** one LUT2 at fanout 3 feeding the LUT6s for `alu_ctrl[2:0]`; `alu_ctrl[3]` on its own LUT4, LUT5 chain at fanout 1

**Prediction:** 12 (counting muxes), 8 (counting input cones), actual 5

## Full single-cycle datapath, post-synthesis at 20ns OOC

| Metric            | Value                        |
| ----------------- | ---------------------------- |
| WNS               | −0.305 ns                    |
| Failing endpoints | 8 of 694                     |
| Data path delay   | 13.238 ns                    |
| *logic*           | 3.223 ns (24%)               |
| *routing*         | 10.015 ns (76%)              |
| Logic levels      | 20                           |
| CARRY4            | 7                            |
| WHS               | +0.478 ns, 0 hold violations |

Input delay was 8ns, leaving the module 12 of 20; so the failure is partly artificial. All nets unplaced.

### Critical path

```text
inst[2]
opcode decode
register file
ALU
32-bit reduce
branch_sig (fanout 59)
PC carry chain
usable_pc_reg[31]
```

## Whole design primitives

After BRAM fix. Includes ALU, regfile, immgen, LSU, UART.

| Category | Count         |
| -------- | ------------- |
| **LUTs** | **938 total** |
| *LUT6*   | 454           |
| *LUT5*   | 270           |
| *LUT4*   | 88            |
| *LUT3*   | 79            |
| *LUT2*   | 42            |
| *LUT1*   | 5             |
| RAMB36E1 | 4             |
| RAMD32   | 68            |
| RAMS32   | 20            |
| CARRY4   | 44            |
| MUXF7    | 24            |
| FDRE     | 62            |
| FDSE     | 1             |


# load_store

In particular, `load_store` was done quite poorly. The memory array is tightly coupled to the actual load and store logic, and at first it was so bad that synthesis could not infer the BRAM even with the `ram_style = "block"` .  There was a conditional read and a mux that decided the write, with the intention to structure into a byte-enabled write based on outside factors and unconditional read that goes through under certain outside conditions, but since it was so coupled, I was unable to see that that structure wasn't present at all, so inference of BRAM failed. Here's what that looked like before and after culling it down to force it into something resembling the inference template:

| Primitive | Before | After |
| --------- | -----: | ----: |
| RAMS64E   |   2048 |     0 |
| MUXF7     |   1119 |    24 |
| MUXF8     |    536 |     0 |
| LUT6      |    590 |   454 |
| RAMB36E1  |      0 |     4 |