#!/usr/bin/env python3
"""Run two RTL mutations in isolated copies and verify regression rejects them."""
import csv
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

project = Path(__file__).resolve().parent.parent
rtl = project / "fifo.sv"
golden = rtl.read_bytes()
source = golden.decode()
mutations = [
    ("full_threshold", "assign full  = (count == 5'd16);",
     "assign full  = (count == 5'd15);", "FULL AFTER mismatch"),
    ("read_address", "dout   <= mem[rd_ptr];",
     "dout   <= mem[rd_ptr ^ 4'd1];", "FIFO MISMATCH"),
]
for name, original, replacement, mismatch in mutations:
    if source.count(original) != 1:
        raise SystemExit("Golden RTL does not match the documented mutation: " + name)

(project / "report").mkdir(exist_ok=True)
output = Path(tempfile.mkdtemp(prefix="mutations_", dir=str(project / "report")))
print("Mutation reports: " + str(output), flush=True)
results = []
for name, original, replacement, mismatch in mutations:
    isolated = output / name
    isolated.mkdir()
    for path in list(project.glob("*.sv")) + [project / "files.f", project / "regression.sh"]:
        shutil.copy2(path, isolated / path.name)
    (isolated / "fifo.sv").write_text(source.replace(original, replacement))
    # A mutant must make the existing regression fail, including the FULL test.
    result = subprocess.run(["bash", "regression.sh", "1"], cwd=str(isolated),
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            universal_newlines=True, timeout=240)
    (output / (name + "_regression.log")).write_text(result.stdout)
    summaries = list((isolated / "report").glob("regression_*/summary.csv"))
    if result.returncode != 1 or len(summaries) != 1:
        raise SystemExit("Expected a completed failing regression for " + name)
    with summaries[0].open() as stream:
        rows = list(csv.DictReader(stream))
    full = next(row for row in rows if row["run"] == "full_s1")
    log = Path(full["log"]).read_text()
    if (full["status"] != "FAIL" or int(full["checks"]) != 152 or
            int(full["errors"]) <= 0 or mismatch not in log or
            "[TB] TEST FULL PASSED" in log or "TEST FULL FAILED" not in log):
        raise SystemExit("Expected checker evidence missing for " + name)
    if name == "read_address" and int(full["errors"]) != 16:
        raise SystemExit("Read-address mutation did not produce the expected 16 mismatches")
    if len(rows) != 7:
        raise SystemExit("Mutant regression did not complete all seven runs")
    shutil.copy2(full["log"], output / (name + "_fail.log"))
    results.append(dict(mutation=name, test="FULL", seed=1,
                        checks=int(full["checks"]), errors=int(full["errors"]),
                        coverage_percent=float(full["coverage_percent"]),
                        full_exit=int(full["exit_code"]), regression_exit=result.returncode,
                        detected=True))
    print("DETECTED {}: FULL checks={} errors={} coverage={}% regression_exit={}".format(
        name, full["checks"], full["errors"], full["coverage_percent"], result.returncode), flush=True)

if rtl.read_bytes() != golden:
    raise SystemExit("Golden RTL changed during mutation experiments")
(output / "summary.json").write_text(json.dumps(dict(
    golden_sha256=hashlib.sha256(golden).hexdigest(), mutations=results), indent=2) + "\n")
print("Golden RTL unchanged; rerun ./regression.sh to confirm golden behavior.", flush=True)
