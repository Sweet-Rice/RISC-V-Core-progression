# ALU

Target: Arty A7 (Artix-7), Vivado, RV32I ALU, purely combinational, parameterized on `W` (default 32).

---

## Arithmetic and logic

add and sub will derive from CARRY4. too much work for a loss in perf otherwise.

slt and sltu also derive from CARRY4. I originally left these to inference, which was wrong. it spun up 3 separate carry chains where 1 does the job. fixed later.

xor, or, and are all logic gates. free.

---

## Shifts

Now the shift instructions.

3 operations, arithmetic right, logical right, logical left. can be compressed to one hardware module.

Many approaches I've seen and they all involve muxes, but that extends our critical path for the shifter by at least ~4:1 muxes.
To avoid this, we need to approach the problem from a selection perspective. How should we select the fill bit? How should we select the direction?

Thankfully, bit math is pretty cool. If we reverse the register, shifting right is literally just shifting left if you reverse it after the shift.
This cuts down our instantiation cost significantly, Since we can create 2 sets of 32 wires reversing the input and reversing the output.
Direction selection can just be selecting the reversed output.

### Opcode encoding

Additionally, we can opt to abuse the very intelligently designed opcodes that the risc architects have so graciously given us:

| Instruction | `{inst[30], funct3}` |
|---|---|
| sll | `0001` |
| srl | `0101` |
| sra | `1101` |

Do note that op[2] is the only differentiator between sll and the right shifts. Sll is also conveniently the only one that reverses.
Not very helpful since we already make decisions based on an opcode mux, but cool regardless.

The more interesting finding is that op[3] is the only differentiator between sra and the logical shifts. Sra is conveniently the only one that requires a variable fill bit.
This means we can select a fill bit via `op[3] & a[W-1]`, requiring only an AND gate, dropping the mux for a fill bit.

For reversing, unfortunately we have to tank a loss here and absorb a 2:1 mux, though it exists inside the alu itself.

---

## Results

Originally, I had written the generate loop, but upon further analysis, operators actually infer better. writing the stages out explicitly locks the structure in, so vivado cant reshuffle it into something that packs cleaner.
I had more dedicated mux hardwares and less full LUT6es, so with operators, I dropped 29 LUTs. never timed the generate version so I cant claim speed either way. Upsetting. It's fine.

On the bright side, raw operators wasn't good enough for the arithmetic instructions. add, sub, slt and sltu each inferred their own carry chain. Creating a shared module for those actually saved me a ton.

### Synthesis progression

| Version | LUT count | CARRY4 | MUXF7 |
|---|---|---|---|
| Core ops only, no shifter | 163 slice LUTs | 24 | 28 |
| + explicit generate shifter | 460 raw LUT primitives | 24 | 28 |
| + shared `addsub` module | 341 raw LUT primitives | **9** | 32 |
| + operator shifter | **312 raw LUT primitives** | 9 | **0** |

Slice LUTs and raw LUT primitive counts are different measurements and should not be compared directly.

### LUT distribution

| | explicit shifter, separate comparators | explicit shifter, shared addsub | operator shifter, shared addsub |
|---|---|---|---|
| LUT6 | 129 | 190 | 200 |
| LUT5 | 88 | 66 | 42 |
| LUT4 | 103 | 39 | 32 |
| LUT3 | 59 | 46 | 36 |
| LUT2 | 81 | 0 | 2 |
| **total** | **460** | **341** | **312** |

### Timing

Post-synthesis, unconstrained, `report_timing -from [all_inputs] -to [all_outputs]`. These recorded results came from the older `xc7a35ticsg324-1L` synthesis run; the project now targets `xc7a100tcsg324-1`.

| | |
|---|---|
| Worst path, pad to pad | 9.68 ns |
| IO buffer overhead (IBUF + OBUF) | 3.61 ns |
| Remaining after I/O buffer overhead | 6.07 ns |
| Logic share | 4.35 ns (45%) |
| Route share | 5.33 ns (55%) |
| LUT levels | 6 |
| Critical path source | `op[3]`, fanout 155 |

every LUT costs 0.124 ns, every net costs 0.4 to 0.9 ns. routing is more than half the delay.

critical path isnt data through the adder, its op[3] fanning out to 155 places. it drives the result mux, the addsub subtract input, the shifter fill AND, and the sh_in reversal mux. carry chain doesnt show up in the top 10 paths at all.
