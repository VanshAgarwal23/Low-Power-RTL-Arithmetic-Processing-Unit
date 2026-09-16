# Results and Analysis

## 1. Overview

The Low-Power RTL Arithmetic Processing Unit was implemented using Verilog HDL and evaluated through functional simulation, RTL synthesis, switching-activity analysis, and ASIC implementation using the SKY130A technology library and OpenLane.

Three implementations were evaluated:

1. Conventional APU
2. Low-Power APU using operand isolation
3. Pipelined APU

The objective was to study the trade-offs between functionality, switching activity, area, and timing.

---

## 2. Functional Verification

The conventional APU was verified using dedicated testbenches for the arithmetic and logic operations.

The pipelined APU was additionally verified using 26 functional test cases covering:

- Addition
- Carry generation
- Signed overflow
- Zero-result conditions
- Subtraction
- Borrow generation
- Negative results
- Multiplication
- Maximum-value multiplication
- Division
- Division by zero
- AND
- OR
- XOR
- NOT

All 26 pipelined APU test cases passed successfully.

**Verification result: 26/26 PASS**

The pipelined architecture therefore preserved the expected functional behavior while introducing pipeline registers.

---

## 3. Operand Isolation Analysis

The low-power APU uses operand isolation to prevent unnecessary input activity from reaching inactive functional units.

When an operation is not selected, its operands are forced to zero before entering the corresponding datapath.

The observed switching activity demonstrates this behavior. For example, the inactive subtractor inputs showed zero transitions during the analyzed workload.

The activity analysis demonstrates switching suppression in inactive datapaths. However, transition counts are not directly equivalent to measured power consumption and therefore are not reported as a percentage power reduction.

---

## 4. ASIC Implementation

ASIC implementation was performed using:

- SKY130A PDK
- sky130_fd_sc_hd standard-cell library
- OpenLane
- OpenROAD
- Magic
- KLayout

The pipelined APU completed the complete OpenLane implementation and signoff sequence, including routing, parasitic extraction, multi-corner timing analysis, GDS generation, LVS, DRC, antenna checking, and ERC.

No DRC violations were reported after detailed routing or GDS streaming.

---

## 5. ASIC Area Comparison

| Parameter | Conventional APU | Low-Power APU | Pipelined APU |
|---|---:|---:|---:|
| Die Area (mm²) | 0.07424 | 0.07921 | 0.09182 |
| Core Area (µm²) | 65,392.7 | 69,907.0 | 81,847.2 |
| Synthesized Cells | 2,925 | 3,102 | 3,109 |
| Physical Cells | 8,996 | 9,601 | 11,088 |
| Placement Utilization | 41.29% | 41.37% | 36.14% |

The operand-isolated implementation requires additional isolation logic, resulting in increased area compared with the conventional implementation.

The pipelined implementation requires additional sequential elements and associated physical resources, resulting in the largest die area among the three implementations.

---

## 6. Timing Analysis

The target clock period was 10 ns.

The final pipelined implementation reported:

- Critical path: 26.94 ns
- Suggested clock period: 28.77 ns
- Suggested frequency: approximately 34.76 MHz
- WNS: -18.50 ns
- TNS: -109.71 ns
- SPEF WNS: -18.77 ns
- SPEF TNS: -115.25 ns

Setup timing violations remained at the 10 ns target.

The pipeline therefore demonstrates a useful architectural timing study, but the selected implementation does not achieve timing closure at the 10 ns target.

This result is retained as an engineering trade-off rather than attempting unlimited RTL optimization.

---

## 7. Pipelined APU Power Result

The OpenLane metrics report provided the following typical-corner power values for the pipelined implementation:

| Power Component | Value |
|---|---:|
| Internal Power | 0.00174 µW |
| Switching Power | 0.00178 µW |
| Leakage Power | 1.95 × 10⁻⁸ µW |

These values are reported only for the implementation for which OpenLane generated the corresponding power metrics.

The conventional and operand-isolated OpenLane runs did not produce comparable final power values, so a direct numerical power comparison is not claimed.

---

## 8. Overall Engineering Trade-off

The three architectures demonstrate different design priorities.

### Conventional APU

The conventional implementation provides the baseline architecture with the lowest measured die area among the evaluated implementations.

### Low-Power APU

The operand-isolated architecture introduces additional hardware but prevents unnecessary operand activity from reaching inactive datapaths.

Its primary benefit is therefore switching-activity reduction rather than minimum area.

### Pipelined APU

The pipelined architecture introduces additional registers and increases physical area. It provides a structured approach for reducing the amount of logic traversed within individual pipeline stages, although the implemented version still contains significant combinational logic and does not meet the 10 ns timing target.

---

## 9. Limitations

The following limitations were identified during the implementation:

1. The arithmetic datapaths, particularly multiplication and division, contribute significant combinational complexity.
2. Operand isolation introduces additional area and control logic.
3. The implemented pipeline does not achieve timing closure at the 10 ns target.
4. Comparable final power measurements were not available for all three OpenLane implementations.
5. Switching activity measurements demonstrate activity suppression but should not be interpreted directly as percentage power savings without equivalent power modeling conditions.

---

## 10. Conclusion

The project demonstrates a complete RTL-to-ASIC design study of an arithmetic processing unit.

The conventional design establishes the functional and physical baseline. Operand isolation demonstrates an RTL-level low-power technique for reducing unnecessary switching in inactive datapaths. The pipelined architecture demonstrates the effect of introducing sequential boundaries into the datapath.

The study shows that RTL optimization involves trade-offs between area, switching activity, timing, and architectural complexity. Rather than optimizing a single metric in isolation, the project evaluates these trade-offs using functional verification, synthesis results, switching-activity analysis, and SKY130A ASIC implementation.
