# Portfolio Summary

**Project title:** Synchronous FIFO Functional Verification Using SystemVerilog

**Repository description:** Self-checking non-UVM SystemVerilog verification of a synchronous FIFO with directed/random tests, queue-based scoreboard, SVA, functional coverage, multi-seed regression, and isolated RTL mutations.

**Tools:** SystemVerilog, Cadence Xcelium 25.03, Bash, Python.

## CV bullets

- Developed a non-UVM verification environment for an 8-bit, 16-entry synchronous FIFO using classes, mailboxes, a virtual interface, cycle-aware monitoring, and a queue-based reference scoreboard.
- Implemented directed and constrained-random testing, SVA, seven functional coverage categories, and an automated 11-run regression; achieved 100% of the defined coverage model in a cumulative SUITE simulation.
- Validated checker sensitivity with two isolated RTL mutations: an early FULL flag and corrupted read addressing; confirmed regression rejects the mutants and passes with golden RTL.

The coverage result refers to the implemented bins, not exhaustive verification or merged independent runs. Back-to-back coverage is at request level.

**Suggested topics:** systemverilog, design-verification, fifo, sva, functional-coverage, cadence-xcelium, non-uvm.
