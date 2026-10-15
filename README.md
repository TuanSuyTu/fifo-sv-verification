# Synchronous FIFO Verification in SystemVerilog

A self-checking, non-UVM verification environment for an **8-bit, 16-entry synchronous FIFO**, tested with Cadence Xcelium 25.03-s001.

The environment uses constrained-random transactions, mailboxes, a virtual interface, a queue-based scoreboard, SVA, and functional coverage. The default regression runs **11 simulations**; the cumulative **SUITE reaches 100% of the implemented functional coverage model**. Two isolated RTL mutations demonstrate checker sensitivity.

## DUT contract

- WRITE is accepted on a rising clock edge when the FIFO is not FULL.
- READ is accepted when the FIFO is not EMPTY; `dout` receives the oldest entry.
- Overflow writes and underflow reads are rejected.
- Active-high synchronous reset clears pointers and occupancy. Memory and `dout` need not reset.
- Simultaneous READ/WRITE is outside this project's contract; stimulus constrains it away and SVA checks mutual exclusion.

## Verification flow

```text
Generator -> transaction mailbox -> Driver -> fifo_if -> DUT
                                                |
                                             Monitor
                                                |
                                        observation mailbox
                                                |
                                  Scoreboard + functional coverage
```

The Driver drives falling edges. The Monitor samples requests and pre-update flags at rising edges, then captures post-update outputs at the following falling edge. The Scoreboard predicts accepted operations from its own queue occupancy, checks FULL/EMPTY before and after each operation, and checks accepted READ data. Concurrent SVA checks reset response, mutual exclusion, and read-while-empty behavior.

## Run

Requirements: a licensed Xcelium environment with `xrun` on `PATH`, Bash, Python 3.6+, GNU `timeout`, and `make` for the optional Makefile targets. Configure your simulator environment before running; no machine-specific setup or license files are included.

```sh
make compile
make sim                         # Default: FULL
./regression.sh                  # Directed tests, five RANDOM seeds, SUITE
./regression.sh 7 19 2026         # Custom RANDOM seeds
```

Run one testcase from the repository root:

```sh
mkdir -p work
cd work
xrun -F ../files.f +TEST=SUITE -svseed 1 -covtest suite_s1
```

| Test | Main objective |
|---|---|
| FULL | Fill, reject overflow, drain and check ordering |
| EMPTY | Reject underflow, then verify a legal WRITE/READ |
| WRAP | Exercise circular addressing with readback |
| RESET | Reset with three pending entries; verify recovery |
| RESET_EMPTY | Reset an empty FIFO |
| RANDOM | 200 constrained-random requests per seed |
| CLOSURE | Target idle occupancy bins and consecutive READ/WRITE |
| SUITE | Run all scenarios with one persistent coverage instance |

`regression.sh` uses RANDOM seeds `1, 2, 3, 42, 123` by default. It records simulator status, checks, errors, coverage, and transaction counts in `report/regression_*/summary.csv`. Each run has a 30-second timeout and separate log/database. Errors, missing checks, missing coverage data, or unmet SUITE coverage make regression exit nonzero.

## Coverage and evidence

Seven coverage categories track operations, occupancy, their cross, accepted write data, reset episodes, reference-pointer wraps, and back-to-back requests. SUITE resets DUT/reference state between scenarios while retaining one covergroup. **It does not merge independent coverage databases and requires no IMC.**

A 100% result means all currently defined bins were hit, not that every FIFO defect or requirement has been proven. Back-to-back bins measure requests, including rejected boundary requests; the middle occupancy bin groups values 2–14.

- [Verification plan](docs/VERIFICATION_PLAN.md): requirements, stimulus, checkers, and coverage.
- [Verified results](docs/VERIFICATION_RESULTS.md): fresh regression measurements and evidence.
- [Bug injection](docs/BUG_INJECTION.md): early FULL and corrupted read-address experiments.
- [Evidence](evidence/README.md): selected simulator logs and regression CSV.
- [Portfolio description and CV bullets](docs/PORTFOLIO.md).

Run the isolated mutation experiments with:

```sh
python3 scripts/bug_injection.py
```

The script copies sources into generated experiment directories, verifies that regression rejects each mutant, and confirms the golden `fifo.sv` is unchanged.

## Source map

Sources remain at the repository root to preserve the working filelist: `fifo.sv`, `fifo_if.sv`, `transaction.sv`, `generator.sv`, `driver.sv`, `monitor.sv`, `fifo_observation.sv`, `scoreboard.sv`, and `tb_fifo.sv`. `files.f` defines compilation order and enables SVA cover directives and functional coverage. Generated simulation and coverage files are excluded from Git; selected text evidence is tracked.
