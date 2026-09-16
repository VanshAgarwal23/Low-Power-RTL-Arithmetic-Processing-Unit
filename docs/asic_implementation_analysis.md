# ASIC Implementation and Switching Activity Analysis

## 1. Objective

This analysis evaluates the ASIC implementation characteristics of two versions of the Arithmetic Processing Unit (APU):

1. Conventional APU
2. Low-Power APU with operand isolation

Both designs implement the same arithmetic and logic functionality. The low-power implementation introduces operand isolation to reduce unnecessary switching activity in inactive datapaths.

The designs were evaluated using the SKY130 `sky130_fd_sc_hd` standard-cell library through the OpenLane ASIC implementation flow.

The analysis focuses on:

* Synthesis cell count
* Physical cell count
* Die area
* Core area
* Placement utilization
* Routing wire length
* Logic depth
* Critical-path timing
* Switching activity
* Effect of operand isolation
* Limitations of post-layout power estimation

---

## 2. Design Architecture

The APU uses 16-bit operands and produces a 32-bit result.

### Supported operations

| Opcode | Operation |
| ------ | --------- |
| `000`  | ADD       |
| `001`  | SUB       |
| `010`  | MUL       |
| `011`  | DIV       |
| `100`  | AND       |
| `101`  | OR        |
| `110`  | XOR       |
| `111`  | NOT A     |

The APU also generates seven status flags:

| Bit | Flag | Description     |
| --: | ---- | --------------- |
|   0 | Z    | Zero            |
|   1 | N    | Negative        |
|   2 | C    | Carry           |
|   3 | B    | Borrow          |
|   4 | V    | Signed overflow |
|   5 | P    | Even parity     |
|   6 | D    | Divide-by-zero  |

The conventional design directly applies the input operands to the computational units.

The low-power design introduces operand isolation between the top-level operands and the individual computational datapaths. When a datapath is inactive, its isolated operands are driven to constant zero values.

---

## 3. ASIC Implementation Flow

The implementation flow used:

```text
RTL
 ↓
Synthesis
 ↓
Floorplanning
 ↓
Placement
 ↓
Clock Tree Synthesis
 ↓
Routing
 ↓
RCX / Parasitic Extraction
 ↓
Signoff STA
```

Technology:

```text
PDK              : SKY130A
Standard Cell    : sky130_fd_sc_hd
Clock Constraint : 10 ns
Target Frequency : 100 MHz
Core Utilization : 40%
Placement Target : 50%
```

Both designs successfully progressed through the physical implementation stages up to parasitic extraction.

---

## 4. Conventional APU Results

OpenLane run:

```text
RUN_2026.09.16_14.18.07
```

### Implementation metrics

| Metric                | Conventional APU |
| --------------------- | ---------------: |
| Die area              |      0.07424 mm² |
| Core area             |    65,392.72 µm² |
| Synthesized cells     |            4,042 |
| Total physical cells  |            8,996 |
| Placement utilization |           41.29% |
| Wire length           |       80,376,216 |
| Logic depth           |               94 |
| Critical path         |          11.0 ns |
| Suggested frequency   |        90.91 MHz |
| Clock constraint      |            10 ns |
| Standard-cell library |  sky130_fd_sc_hd |

The implementation reached routing successfully. The reported critical path is 11.0 ns compared with the 10 ns clock constraint.

Therefore, the implementation does not satisfy the 10 ns timing target in the reported timing estimate.

---

## 5. Low-Power APU Results

OpenLane run:

```text
RUN_2026.09.16_14.35.45
```

### Implementation metrics

| Metric                |   Low-Power APU |
| --------------------- | --------------: |
| Die area              |     0.07921 mm² |
| Core area             |   69,907.05 µm² |
| Synthesized cells     |           4,282 |
| Total physical cells  |           9,601 |
| Placement utilization |          41.37% |
| Wire length           |      79,566,900 |
| Logic depth           |              97 |
| Critical path         |         11.0 ns |
| Suggested frequency   |       90.91 MHz |
| Clock constraint      |           10 ns |
| Standard-cell library | sky130_fd_sc_hd |

The low-power implementation also reached routing before the RCX/SPEF failure.

---

## 6. Conventional vs Low-Power Comparison

| Metric                |  Conventional |     Low-Power |                  Change |
| --------------------- | ------------: | ------------: | ----------------------: |
| Die area              |   0.07424 mm² |   0.07921 mm² |                  +6.69% |
| Core area             | 65,392.72 µm² | 69,907.05 µm² |                  +6.90% |
| Synthesized cells     |         4,042 |         4,282 |                  +5.94% |
| Total physical cells  |         8,996 |         9,601 |                  +6.72% |
| Placement utilization |        41.29% |        41.37% | +0.08 percentage points |
| Wire length           |    80,376,216 |    79,566,900 |                  −1.01% |
| Logic depth           |            94 |            97 |                  +3.19% |
| Critical path         |       11.0 ns |       11.0 ns |               No change |
| Suggested frequency   |     90.91 MHz |     90.91 MHz |               No change |

### Area interpretation

The low-power implementation uses additional isolation logic. This results in an increase in synthesized cell count and physical area.

The synthesized cell count increases from 4,042 to 4,282, corresponding to approximately 5.94%.

The die area increases from 0.07424 mm² to 0.07921 mm², corresponding to approximately 6.69%.

This represents the hardware overhead associated with implementing operand isolation.

### Timing interpretation

Both designs report the same critical path of 11.0 ns and the same suggested frequency of approximately 90.91 MHz.

Therefore, within these OpenLane implementation results, operand isolation did not change the reported critical-path delay.

Both implementations, however, exceed the 10 ns target clock period.

### Routing interpretation

The reported wire length changes from 80,376,216 to 79,566,900.

This corresponds to an approximately 1.01% reduction in reported wire length for the low-power implementation.

The difference is relatively small and should not be interpreted as a primary benefit of operand isolation.

---

## 7. Switching Activity Analysis

Switching activity was evaluated using matched activity workloads.

The workload consists of:

```text
ADD       : 200 cycles
MUL       : 200 cycles
DIV       : 200 cycles
XOR       : 200 cycles
IDLE      : 200 cycles
-----------------------
Total     : 1000 cycles
```

During the idle phase, the top-level operands continue changing while `enable` is deasserted.

The objective is to determine whether operand isolation prevents these changing inputs from propagating into inactive computational datapaths.

---

## 8. Conventional APU Activity

The conventional activity VCD shows the following top-level operand transitions:

| Signal | Transitions |
| ------ | ----------: |
| A      |       1,000 |
| B      |       1,000 |

Because the conventional architecture does not contain operand-isolation boundaries, the changing input operands are directly supplied to the computational datapaths.

---

## 9. Low-Power Operand-Isolation Activity

The low-power activity VCD was analyzed at the isolated operand signals.

| Isolated datapath | A transitions | B transitions |
| ----------------- | ------------: | ------------: |
| ADD               |           200 |           200 |
| SUB               |             0 |             0 |
| MUL               |           201 |           201 |
| DIV               |           201 |           201 |
| Logic             |           201 |           201 |

The SUB datapath shows zero transitions during the workload because it remains inactive while other operations are exercised.

This demonstrates the functional behavior of operand isolation: an inactive datapath receives constant isolated operands instead of continuously changing external input data.

---

## 10. Interpretation of Switching Activity

The switching measurements provide evidence that operand isolation suppresses unnecessary signal transitions in inactive datapaths.

The important observation is:

```text
Changing top-level inputs
          ↓
Operand isolation
          ↓
Inactive datapath receives constant value
          ↓
Reduced internal switching opportunity
```

This is the intended low-power mechanism.

However, transition counts alone do not provide a physical power value.

Dynamic power depends on factors including:

* Switching activity
* Load capacitance
* Cell capacitance
* Supply voltage
* Operating frequency
* Internal cell switching behavior
* Interconnect capacitance

Therefore, this analysis does not claim a specific percentage of power reduction.

---

## 11. Power Estimation Limitation

The OpenLane `metrics.csv` files contain `-1` for all reported power fields:

```text
power_slowest_internal_uW
power_slowest_switching_uW
power_slowest_leakage_uW
power_typical_internal_uW
power_typical_switching_uW
power_typical_leakage_uW
power_fastest_internal_uW
power_fastest_switching_uW
power_fastest_leakage_uW
```

Therefore, valid post-layout power measurements were not generated by these runs.

The OpenLane flow also failed during the RCX/SPEF stage because no SPEF file was produced.

Without valid extracted parasitics, post-layout timing/power analysis cannot be completed through the intended signoff path.

This limitation is treated as a flow/environment limitation rather than a failure of the RTL design.

---

## 12. RCX/SPEF Limitation

Both the conventional and low-power OpenLane runs progressed through routing but failed at the parasitic extraction/signoff stage.

The relevant sequence was:

```text
RTL
 ↓
Synthesis
 ↓
Floorplan
 ↓
Placement
 ↓
CTS
 ↓
Routing
 ↓
RCX
 ↓
SPEF generation failed
 ↓
Final signoff stage unavailable
```

No `.spef` file was generated in the low-power run.

The same RCX/SPEF issue was observed in the conventional run.

Because the same issue affects both implementations, it does not invalidate the comparative area, cell-count, routing, and preliminary timing results already obtained from the completed implementation stages.

---

## 13. Engineering Trade-Off

The results demonstrate the fundamental trade-off associated with operand isolation.

### Conventional architecture

Advantages:

* Lower implementation area
* Lower synthesized cell count
* Simpler datapath structure

### Operand-isolated architecture

Characteristics:

* Additional isolation hardware
* Higher area
* Higher cell count
* Similar reported timing
* Reduced switching activity in inactive datapaths

The low-power architecture therefore introduces hardware overhead in exchange for controlling unnecessary switching activity.

Whether the trade-off is beneficial depends on the eventual power savings achieved under realistic operating workloads.

---

## 14. Results Summary

The ASIC implementation experiments produced the following observations:

1. Both APU implementations successfully progressed through synthesis, floorplanning, placement, CTS, and routing.
2. The low-power implementation increased die area by approximately 6.69%.
3. Synthesized cell count increased by approximately 5.94%.
4. Total physical cell count increased by approximately 6.72%.
5. Reported critical-path delay remained 11.0 ns for both designs.
6. Neither implementation met the 10 ns target timing constraint.
7. Reported wire length decreased by approximately 1.01% in the low-power implementation.
8. Operand-isolation activity measurements demonstrated that inactive datapath operands can remain constant.
9. No numerical power reduction is claimed because valid OpenLane power measurements were unavailable.
10. Both flows encountered the same RCX/SPEF extraction limitation.

---

## 15. Conclusion

The ASIC implementation analysis demonstrates the physical trade-offs introduced by operand isolation in the low-power APU.

The additional isolation logic increases hardware resources and physical area, while the timing result remains unchanged in the current implementation. The switching-activity experiment demonstrates the intended low-power mechanism by preventing changing input operands from propagating into inactive datapaths.

The current results therefore establish a foundation for low-power RTL optimization but do not yet provide a quantified post-layout power saving.

Future work can extend the design with integrated clock gating, more advanced operand isolation, activity-driven power estimation, timing optimization, and improved physical implementation. These techniques can be evaluated using the same conventional-versus-low-power methodology established in this project.
