# Verification Plan

## Contract and scope

The DUT is a single-clock, 8-bit, 16-entry FIFO. Rising edges accept WRITE when not FULL or READ when not EMPTY. Accepted writes append data; accepted reads return the oldest entry. FULL corresponds to occupancy 16 and EMPTY to 0. Rejected requests must not corrupt occupancy or subsequent data ordering.

Active-high synchronous reset clears both pointers and occupancy. The contract does not require clearing memory or `dout`. Simultaneous READ/WRITE is unsupported by this verification contract. CDC, configurable widths/depths, physical timing, and formal proof are outside scope.

## Requirements and detection

| ID | Requirement / failure risk | Stimulus | Checker | Coverage |
|---|---|---|---|---|
| F01 | Accepted WRITE; lost/corrupted data | FULL, RANDOM | Queue model and later readback | WRITE, accepted data |
| F02 | FIFO ordering | Distinct values in FULL, WRAP | READ-data comparison | READ across occupancy categories |
| F03 | FULL at 16; early/late flag | FULL | FULL before/after | FULL occupancy |
| F04 | Reject overflow | 17th WRITE in FULL | Flags and subsequent readback | WRITE × FULL |
| F05 | EMPTY after draining | FULL, WRAP | EMPTY before/after | EMPTY occupancy |
| F06 | Reject underflow; recover correctly | EMPTY, RESET | Flags, SVA, later readback | READ × EMPTY |
| F07 | Circular pointer addressing | WRAP, CLOSURE | Ordered readback | Accepted WRITE/READ wrap |
| F08 | Reset nonempty FIFO; discard pending entries | RESET | Queue clear, reset counter, SVA | Reset NONEMPTY |
| F09 | Reset empty FIFO | RESET_EMPTY | Flags, reset SVA | Reset EMPTY |
| F10 | Consecutive requests | FULL, EMPTY, CLOSURE, RANDOM | Per-cycle queue model | WW, RR, WR, RW |
| F11 | Data patterns | FULL, EMPTY, CLOSURE, RANDOM | READ-data comparison | Accepted 00, FF, others |
| F12 | Supported stimulus protocol | All tests | READ/WRITE mutual-exclusion SVA | Simultaneous requests excluded |

Coverage is scenario evidence, not a correctness checker. Pointer correctness is checked indirectly through flags and subsequent data, rather than through DUT-internal assertions.

## Sampling and completion

1. Driver drives requests on falling edges; consecutive requests require no inserted idle cycle.
2. DUT samples rising edges and updates registers with nonblocking assignments.
3. Monitor records requests and pre-update flags at the rising edge; outputs and post-update flags at the following falling edge.
4. Scoreboard samples coverage using pre-operation reference occupancy, then applies the observation once to its independent queue.
5. Each scenario waits for the next rising edge and an additional 1 ns before completion checks/reporting, allowing the last observation and current assertion evaluation to settle.

Driver and Monitor share falling edges but access different signals at that edge: Driver updates input controls/data, while Monitor captures DUT outputs and flags. This scheduling assumes the present synchronous DUT and observation structure. A larger testbench should use explicit completion handshakes instead of relying on fixed timing.

## Assertions

| Property | Meaning |
|---|---|
| `a_reset` | Reset sampled high implies EMPTY and not FULL at the next rising-edge sample |
| `a_tb_mutex` | WRITE and READ must not be asserted together |
| `a_read_empty` | READ while EMPTY without reset implies EMPTY at the next sample |

The reset property uses `|=>` because concurrent assertions sample before the DUT's NBA updates. Cover properties record reset while nonempty and READ while empty. An absence of assertion failures alone does not establish non-vacuous exercise of every property in every individual test.

## Functional coverage model

| Item | Explicit bins |
|---|---|
| Operation | IDLE, READ, WRITE |
| Pre-operation occupancy | 0, 1, 2–14, 15, 16 |
| Operation × occupancy | 3 × 5 = 15 cross bins |
| Accepted WRITE data | 00, FF, 01–FE |
| Reset episode start | EMPTY, NONEMPTY |
| Reference-pointer wrap | Accepted WRITE wrap, accepted READ wrap |
| Consecutive requests | WW, RR, WR, RW |

There are 34 bins across the coverpoints and cross. `prev_rst` is updated on every observed cycle so a reset held for multiple cycles counts as one episode. Wrap events require accepted operations. Back-to-back bins describe requests, not necessarily two accepted transfers. The aggregate percentage uses simulator coverpoint/cross weighting; it is not a simple count of all hit bins divided by 34.

## Closure and regression

- Golden directed tests and five default RANDOM seeds must finish with nonzero checks, zero scoreboard errors, no simulator/SVA errors, and saved coverage data.
- SUITE retains one scoreboard/covergroup across FULL, EMPTY, WRAP, RESET, RESET_EMPTY, CLOSURE, and RANDOM, with resets between scenarios.
- CLOSURE inserts IDLE at occupancies 1, 2, 15, and 16, drains, then writes FF immediately after the final READ and reads it back.
- SUITE requires 100% of the current functional model. No bins are excluded to manufacture closure.
- FULL-threshold and read-address mutants must cause real checker failures and nonzero regression status.
- Golden RTL must remain unchanged, and a golden regression must pass after mutation experiments.

The eight testcase names do not imply eight standalone runs in the default regression: CLOSURE is exercised inside SUITE, while RANDOM is repeated across five seeds, giving 11 runs.
