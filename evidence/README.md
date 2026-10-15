# Curated Evidence

These files come from fresh execution of the packaged sources on Rocky
Linux with Cadence Xcelium 25.03-s001. Simulator timestamps and paths are
preserved in the complete text logs; they describe the validation host,
not paths required by a clone of this repository.

| File | Evidence |
|---|---|
| `compile.log` | Successful golden compile/elaboration |
| `full_golden_pass.log` | Golden FULL: 152 checks, zero errors |
| `suite_coverage.log` | Golden SUITE: 1,515 checks, zero errors, all seven categories at 100% |
| `regression_summary.csv` | All 11 golden runs; machine-specific path columns omitted |
| `full_threshold_fail.log` | Early-FULL mutant: 5 scoreboard errors and fatal termination |
| `read_address_fail.log` | Read-address mutant: 16 data errors and fatal termination |
| `mutation_summary.json` | Measured mutation results, exit codes, unchanged golden RTL hash |
| `source_sha256.txt` | Checksums of tested sources and executable scripts |

The source manifest is a derived checksum artifact. The CSV retains the
measured values from the real script output; only log/database path
columns were removed. No PASS/FAIL messages or simulator measurements
were synthesized. Coverage databases and compiled snapshots are not
published. Regenerate them using the commands in the repository README.

From the repository root, verify source identity with:

```sh
sha256sum -c evidence/source_sha256.txt
```
