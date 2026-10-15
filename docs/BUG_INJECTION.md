# Bug Injection Evidence

## Method

`python3 scripts/bug_injection.py` copies the packaged sources into two
isolated experiment directories under `report/mutations_*/`. Each copy
contains one deliberate RTL mutation and runs the existing regression
with RANDOM seed 1: five directed runs, one RANDOM run, and SUITE.
The utility checks that regression fails for a real FULL-test checker
mismatch, rather than treating any tool or compilation failure as proof
of detection. It also checks that the golden `fifo.sv` is unchanged.

The following results are fresh measurements from those experiments,
not reconstructed historical logs. All seven runs completed in each
mutant regression; a subsequent 11-run golden regression passed.

## A. FULL threshold changed from 16 to 15

```systemverilog
// Golden
assign full = (count == 5'd16);
// Mutant
assign full = (count == 5'd15);
```

**Hypothesis:** FULL is asserted one accepted entry too early. The 16th
WRITE is rejected even though the reference queue expects it to succeed.

**Observed evidence:** FULL-before/after mismatches appear at occupancy
15. Later EMPTY mismatches and `expected=0f actual=0e` show the final
reference entry is missing. FULL reports 152 checks and 5 scoreboard
errors, then terminates through `$fatal(1)` with xrun exit 2. The enclosing
regression returns 1.

**Root cause and fix:** The occupancy comparison uses the wrong capacity.
Restore the threshold to 16. Queue-based flag prediction detects the
initial defect independently of the DUT's `full` output.

[Complete failure log](../evidence/full_threshold_fail.log).

## B. Read address changed to `rd_ptr ^ 4'd1`

```systemverilog
// Golden
 dout <= mem[rd_ptr];
// Mutant
 dout <= mem[rd_ptr ^ 4'd1];
```

**Hypothesis:** Flipping the least-significant address bit exchanges each
pair of adjacent memory entries while leaving count/flag logic unchanged.

**Observed evidence:** FULL writes values 00–0F, attempts one overflow,
then reads 16 entries. The log contains `expected=00 actual=01`,
`expected=01 actual=00`, and the same adjacent-pair reversal through 0F.
There are 152 checks and 16 scoreboard errors. No FULL-test PASS marker
appears; `$fatal(1)` produces xrun exit 2 and regression exit 1.

**Root cause and fix:** The read address no longer equals the read
pointer. Restore `mem[rd_ptr]`. Correct occupancy flags alone cannot
establish correct read data; the independent reference queue detects it.

[Complete failure log](../evidence/read_address_fail.log).

## Proof of golden behavior and coverage interpretation

The utility's [summary](../evidence/mutation_summary.json) records the
unchanged golden RTL SHA-256, measured errors, and failure exit codes.
The [golden FULL log](../evidence/full_golden_pass.log) reports the same
152 checks with zero errors and PASS. The subsequent
[golden regression](../evidence/regression_summary.csv) passed all 11 runs.

Both mutants still report 72.62% functional coverage for FULL, the same
as golden FULL. Request and reference-occupancy scenarios occurred even
though DUT behavior was wrong. Coverage and correctness are separate.

These two mutations demonstrate sensitivity to two concrete fault
classes. They do not prove the testbench detects every possible defect.
