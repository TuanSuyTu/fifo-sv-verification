# Verification Results

## Reproduction and provenance

These measurements were freshly reproduced on Rocky Linux with Xcelium
25.03-s001 using the packaged sources. Both isolated mutation experiments
ran first, followed by the golden regression:

```sh
python3 scripts/bug_injection.py
./regression.sh
```

The golden regression returned exit 0. Each mutant's seven-run regression
returned exit 1; the mutation experiment script returned exit 0 because
both expected defects were detected. The golden RTL remained unchanged.
[Source checksums](../evidence/source_sha256.txt) identify the tested
RTL, testbench, build files, and executable scripts.

## Golden regression

| Run | Checks | Errors | Functional coverage | Result |
|---|---:|---:|---:|---|
| full_s1 | 152 | 0 | 72.62% | PASS |
| empty_s1 | 21 | 0 | 39.29% | PASS |
| wrap_s1 | 166 | 0 | 75.24% | PASS |
| reset_s1 | 45 | 0 | 52.14% | PASS |
| reset_empty_s1 | 12 | 0 | 15.71% | PASS |
| random_s1 | 855 | 0 | 80.95% | PASS |
| random_s2 | 859 | 0 | 76.19% | PASS |
| random_s3 | 875 | 0 | 68.57% | PASS |
| random_s42 | 871 | 0 | 69.52% | PASS |
| random_s123 | 855 | 0 | 76.19% | PASS |
| suite_s1 | 1515 | 0 | 100.00% | PASS |

All 11 runs produced nonempty coverage data, matched expected Driver
transaction counts, and had no simulator errors or SVA failures. The
known `CGDEFN` warning assigns a default covergroup-instance name; it did
not prevent sampling or data saving.

The [CSV](../evidence/regression_summary.csv) is a projection of the real
regression summary with machine-specific log/database paths omitted.
Selected complete simulator logs are preserved for
[FULL](../evidence/full_golden_pass.log) and
[SUITE](../evidence/suite_coverage.log).

## Cumulative SUITE

SUITE executes 317 Driver transactions and performs 1,515 scoreboard
checks, with zero errors. All seven coverage categories report 100%:
operation, occupancy, operation × occupancy, accepted data, reset,
pointer wrap, and back-to-back requests. Both SVA cover messages occur.

This is one simulation with one persistent covergroup instance. It is
not an IMC merge of independent regression databases. Individual run
percentages are neither summed nor averaged to obtain the SUITE result.

## Checker sensitivity

| Mutation | FULL checks | Scoreboard errors | FULL coverage | xrun exit | Regression exit |
|---|---:|---:|---:|---:|---:|
| full_threshold | 152 | 5 | 72.62% | 2 | 1 |
| read_address | 152 | 16 | 72.62% | 2 | 1 |

See [bug-injection analysis](BUG_INJECTION.md) and the
[machine-readable mutation summary](../evidence/mutation_summary.json).
The read-address mutant preserves FULL's coverage percentage while
failing all 16 data comparisons: coverage does not replace checking.

## Interpretation limits

The 100% goal applies only to the defined coverage model. Middle occupancy
and OTHER data are grouped bins; back-to-back coverage is request-level.
There is no formal proof, code-coverage closure claim, simultaneous
READ/WRITE verification, or independent database merge. A fixed delay
currently drains final observations; a larger environment should use an
explicit completion handshake. SVA is limited to the three implemented
properties, and this work does not claim comprehensive assertion coverage.
