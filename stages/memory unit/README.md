# Post game analysis

These modules are the result of the god awful mess that happened in ../decoder. Things worked well here and were reasoned through.

---

# Architecture

I decided to pursue Harvard architecture. While the goal is a modified Harvard so that everything lives in the same memory block (but different buses) for a gpu, I settled for standard Harvard as it was the quickest to implement. As such, `fetch` and `load_store` each instantiate their own `memory_arr`.

This was also really... lazy on my part since it pretty much eliminates hazards that might appear in the future for a pipelined core, as IF and MEM are going to be able to access at the same time. However, this is also the entire benefit of modified Harvard, so not too much laziness on my part.

Unfortunately, the consequence of this is that instructions are basically permanent (in the sense that it's invisible to `load_store`). Another UART would need to exist in `fetch`.

---

# Measurements

## `load_store` standalone

Synthesized as top; includes `memory_arr` and `uart`.

| PrimitiveCount |               |
| -------------- | ------------: |
| **LUTs**       | **114 total** |
| *LUT6*         |            49 |
| *LUT5*         |            26 |
| *LUT4*         |            22 |
| *LUT3*         |             9 |
| *LUT2*         |             6 |
| *LUT1*         |             2 |
| RAMB36E1       |             4 |
| CARRY4         |             3 |
| FDRE           |            31 |
| BUFG           |             1 |

