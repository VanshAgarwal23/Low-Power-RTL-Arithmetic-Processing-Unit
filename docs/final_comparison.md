# Final Architecture Comparison

## Implementations

The project evaluates three implementations:

1. Conventional APU
2. Low-Power APU using operand isolation
3. Two-stage pipelined APU

## Comparison

| Parameter | Conventional | Low-Power | Pipelined |
|---|---:|---:|---:|
| Die area (mm²) | 0.07424 | 0.07921 | 0.09182 |
| Core area (µm²) | 65,392.72 | 69,907.05 | 81,847.25 |
| Synthesized cells | 2,925 | 3,102 | 3,109 |
| Physical cells | 8,996 | 9,601 | 11,088 |
| Utilization (%) | 41.29 | 41.37 | 36.14 |
| Critical path (ns) | — | — | 26.94 |
| Typical internal power (µW) | — | — | 0.00174 |
| Typical switching power (µW) | — | — | 0.00178 |
| Magic DRC | — | — | 0 |
| LVS errors | — | — | 0 |

## Conventional APU

The conventional implementation provides the baseline arithmetic-processing architecture.

## Low-Power APU

Operand isolation prevents unnecessary input activity from propagating into inactive functional units. The technique introduces additional isolation hardware.

## Pipelined APU

The pipelined implementation uses two stages and introduces sequential elements between processing stages. It demonstrates a timing-oriented architectural modification with additional hardware overhead.

## Engineering Trade-off

The three implementations demonstrate different architectural trade-offs involving hardware overhead, switching activity and timing structure.

No implementation is treated as universally superior; the comparison is based on the measured characteristics of each architecture.

## Limitations

The final pipelined physical implementation did not close the 10 ns timing target and reported antenna findings. These results are documented as limitations of the current implementation.

## Conclusion

The project demonstrates the progression from conventional RTL through low-power RTL and pipelined RTL to ASIC physical implementation and verification.
