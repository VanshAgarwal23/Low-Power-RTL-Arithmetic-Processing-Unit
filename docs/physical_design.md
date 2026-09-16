# Physical Design and ASIC Signoff

## Overview

The pipelined APU was taken through an RTL-to-GDS ASIC implementation flow using OpenLane and the SKY130A PDK.

Flow:

RTL → Synthesis → Floorplan → Placement → CTS → Routing → SPEF → STA → GDS → DRC → LVS

OpenLane Run: `RUN_2026.09.16_17.06.56`

## Physical Results

| Parameter | Result |
|---|---:|
| Die area | 0.09182 mm² |
| Core area | 81,847.25 µm² |
| OpenDP utilization | 36.14% |
| Synthesized cells | 3,109 |
| Physical cells | 11,088 |
| Signal nets | 3,324 |
| Wire length | 107,782 |
| Vias | 24,107 |

## Generated Artifacts

The final implementation generated:

- GDS
- DEF
- LEF
- SPEF
- SPICE

The design was successfully opened and inspected using KLayout and Magic.

## Physical Verification

### Magic DRC

**0 DRC violations**

### LVS

**0 LVS errors**

No net, device, pin or property mismatches were reported.

## Timing

| Metric | Result |
|---|---:|
| Critical path | 26.94 ns |
| WNS | -18.50 ns |
| TNS | -109.71 ns |
| SPEF WNS | -18.77 ns |
| SPEF TNS | -115.25 ns |
| Suggested clock period | 28.77 ns |
| Suggested frequency | 34.76 MHz |

The implementation did not achieve the 10 ns timing target. Timing optimization was intentionally limited because the project focuses on demonstrating the complete ASIC implementation flow and architectural trade-offs.

## Power

| Parameter | Typical value |
|---|---:|
| Internal power | 0.00174 µW |
| Switching power | 0.00178 µW |
| Leakage power | 1.95 × 10⁻⁸ µW |

## Antenna Findings

The final metrics reported:

- Pin antenna violations: 4
- Net antenna violations: 4

These findings are retained as implementation limitations.

## Conclusion

The pipelined APU successfully progressed through synthesis, floorplanning, placement, CTS, routing, parasitic extraction and GDS generation. The final physical implementation was inspected in KLayout and Magic and passed Magic DRC and LVS with zero reported errors.
