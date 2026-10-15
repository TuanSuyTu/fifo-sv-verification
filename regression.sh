#!/usr/bin/env bash
# Run directed tests, multiple random seeds, and cumulative SUITE coverage.
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if ! command -v xrun >/dev/null 2>&1; then
    echo "xrun is not on PATH. Source your licensed Cadence environment first." >&2
    exit 127
fi
command -v xrun >/dev/null
command -v python3 >/dev/null
command -v timeout >/dev/null

python3 - "$project_dir" "$@" <<'PYTHON'
import csv
import datetime
from pathlib import Path
import re
import subprocess
import sys
import tempfile

project = Path(sys.argv[1])
seed_args = sys.argv[2:] or ["1", "2", "3", "42", "123"]
if any(not s.isdigit() or not 1 <= int(s) <= 2147483647 for s in seed_args):
    sys.exit("Seeds must be integers in 1..2147483647. Usage: ./regression.sh [seed ...]")
seeds = list(dict.fromkeys(int(s) for s in seed_args))
work = project / "work"
work.mkdir(exist_ok=True)
(project / "report").mkdir(exist_ok=True)
report = Path(tempfile.mkdtemp(
    prefix="regression_" + datetime.datetime.now().strftime("%Y%m%d_%H%M%S") + "_",
    dir=str(project / "report")))
print("Reports: " + str(report), flush=True)

def invoke(args, log_path):
    result = subprocess.run(["timeout", "30s", "xrun"] + args,
                            cwd=str(work), stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, universal_newlines=True)
    log_path.write_text(result.stdout)
    return result.returncode, result.stdout

code, log = invoke(["-elaborate", "-F", "../files.f"], report / "compile.log")
if code or re.search(r"\*[EF],", log):
    sys.exit("Compile/elaboration failed; see " + str(report / "compile.log"))

runs = [(name, 1) for name in ("FULL", "EMPTY", "WRAP", "RESET", "RESET_EMPTY")]
runs += [("RANDOM", seed) for seed in seeds]
runs.append(("SUITE", 1))
expected_drivers = {"FULL": 33, "EMPTY": 4, "WRAP": 36, "RESET": 6,
                    "RESET_EMPTY": 0, "RANDOM": 200, "SUITE": 317}
fields = ["run", "test", "seed", "status", "exit_code", "checks", "errors",
          "coverage_percent", "drivers", "log", "coverage_db", "reason"]
failed = 0
print("{:<18} {:<6} {:>7} {:>7} {:>10}".format("RUN", "STATUS", "CHECKS", "ERRORS", "COVERAGE"), flush=True)
with (report / "summary.csv").open("w", newline="") as output:
    writer = csv.DictWriter(output, fieldnames=fields)
    writer.writeheader()
    for test, seed in runs:
        name = test.lower() + "_s" + str(seed)
        log_path = report / (name + ".log")
        code, log = invoke(["-F", "../files.f", "+TEST=" + test,
                            "-svseed", str(seed), "-covworkdir", str(report / "coverage"),
                            "-covtest", name], log_path)
        def value(pattern):
            match = re.search(pattern, log)
            return match.group(1) if match else ""
        checks = value(r"Total Checks\s*:\s*(\d+)")
        errors = value(r"Total Errors\s*:\s*(\d+)")
        coverage = value(r"Functional Coverage:\s*([0-9.]+)%")
        databases = list((report / "coverage").glob("**/" + name + "/*.ucd"))
        reasons = []
        if code: reasons.append("xrun/timeout exit " + str(code))
        if re.search(r"\*[EF],", log): reasons.append("simulator error/fatal")
        if "[TB] TEST " + test + " PASSED" not in log: reasons.append("missing PASS marker")
        if not checks or int(checks) == 0: reasons.append("no checks")
        if errors != "0": reasons.append("scoreboard errors/missing summary")
        if not coverage: reasons.append("coverage missing/disabled")
        if test == "SUITE" and (not coverage or float(coverage) < 100.0):
            reasons.append("SUITE coverage below 100%")
        if log.count("[DRV]") != expected_drivers[test]: reasons.append("transaction count mismatch")
        if not databases or any(p.stat().st_size == 0 for p in databases):
            reasons.append("coverage database missing/empty")
        status = "FAIL" if reasons else "PASS"
        failed += bool(reasons)
        writer.writerow(dict(run=name, test=test, seed=seed, status=status, exit_code=code,
                             checks=checks, errors=errors, coverage_percent=coverage,
                             drivers=log.count("[DRV]"), log=str(log_path),
                             coverage_db=";".join(str(p) for p in databases), reason="; ".join(reasons)))
        output.flush()
        print("{:<18} {:<6} {:>7} {:>7} {:>9}%".format(name, status, checks or "-", errors or "-", coverage or "-"), flush=True)
        if reasons: print("  " + "; ".join(reasons), flush=True)
print("{} runs, {} passed, {} failed".format(len(runs), len(runs) - failed, failed))
print("Summary: " + str(report / "summary.csv"))
sys.exit(1 if failed else 0)
PYTHON
