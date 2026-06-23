#!/usr/bin/env python3
"""Parse IntelliJ headless-inspect output into a unified candidate list.

This script is read-only and makes no network calls. It only reads the
inspection result files under <output-dir> and writes candidates.json beside it.

Usage: parse-intellij.py <output-dir>

<output-dir> is the directory passed to inspect.sh (e.g.
.dead-code-audit/run/intellij). The script reads only the inspection result
files relevant to dead-code detection and writes a normalised JSON list to
<output-dir>/../candidates.json.

Output schema:
  {
    "candidates": [
      {
        "id": "<FQN>" | "<FQN>#<member>",
        "type": "class" | "method" | "field",
        "file": "<repo-relative path>",
        "line": <int>,
        "module": "<module>",
        "package": "<package>",
        "detectors": ["intellij:unused", ...],
        "description": "<problem description>",
        "source_set": "main" | "test" | "integrationTest" | "other"
      },
      ...
    ],
    "false_positives_to_check": [...],
    "summary": {
      "total": N,
      "main": N,
      "test": N,
      "by_type": {...},
      "by_module": {...}
    }
  }
"""

from __future__ import annotations
import json
import sys
from pathlib import Path
from collections import Counter

# Files we consume. Anything else IntelliJ writes is ignored even if present.
RELEVANT = {
    "unused.json": "intellij:unused",
    "UnusedReturnValue.json": "intellij:UnusedReturnValue",
    "RedundantThrows.json": "intellij:RedundantThrows",
    "EmptyMethod.json": "intellij:EmptyMethod",
    # UnusedImport is intentionally excluded — it is a style smell, not a
    # dead-code candidate. IntelliJ emits it at file granularity (no FQN),
    # which pollutes the candidate list with non-actionable entries.
}


def source_set(file_uri: str) -> str:
    if "/src/test/" in file_uri:
        return "test"
    if "/src/integrationTest/" in file_uri:
        return "integrationTest"
    if "/src/main/" in file_uri:
        return "main"
    return "other"


def to_repo_path(file_uri: str) -> str:
    return file_uri.replace("file://$PROJECT_DIR$/", "")


def candidate_id(problem: dict) -> str:
    ep = problem.get("entry_point", {})
    fqname = ep.get("FQNAME", "")
    if not fqname:
        return ""
    # IntelliJ sometimes prefixes the FQN with the enclosing class.
    # e.g. "com.example.Foo java.util.Optional<X> bar(java.lang.String)"
    # Normalise to a stable id by collapsing whitespace.
    parts = fqname.split()
    if len(parts) >= 2:
        return f"{parts[0]}#{parts[-1].split('(')[0]}"
    return fqname


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: parse-intellij.py <output-dir>", file=sys.stderr)
        return 2

    out_dir = Path(sys.argv[1])
    if not out_dir.is_dir():
        print(f"not a directory: {out_dir}", file=sys.stderr)
        return 2

    candidates: list[dict] = []

    for filename, detector_tag in RELEVANT.items():
        path = out_dir / filename
        if not path.is_file():
            continue
        try:
            payload = json.loads(path.read_text())
        except json.JSONDecodeError as exc:
            print(f"warning: failed to parse {path}: {exc}", file=sys.stderr)
            continue

        for problem in payload.get("problems", []):
            ep = problem.get("entry_point", {})
            ctype = ep.get("TYPE", "")
            file_uri = problem.get("file", "")
            candidates.append({
                "id": candidate_id(problem) or ep.get("FQNAME", ""),
                "type": ctype,
                "file": to_repo_path(file_uri),
                "line": problem.get("line"),
                "module": problem.get("module", ""),
                "package": problem.get("package", ""),
                "detectors": [detector_tag],
                "description": problem.get("description", ""),
                "source_set": source_set(file_uri),
            })

    # Merge duplicates (same id from multiple detectors) by union'ing detectors.
    merged: dict[str, dict] = {}
    for c in candidates:
        key = f"{c['id']}|{c['file']}|{c['line']}"
        if key in merged:
            for d in c["detectors"]:
                if d not in merged[key]["detectors"]:
                    merged[key]["detectors"].append(d)
        else:
            merged[key] = c

    final = sorted(merged.values(), key=lambda c: (c["source_set"], c["module"], c["file"], c["line"] or 0))

    summary = {
        "total": len(final),
        "main": sum(1 for c in final if c["source_set"] == "main"),
        "test": sum(1 for c in final if c["source_set"] == "test"),
        "by_type": dict(Counter(c["type"] for c in final)),
        "by_module": dict(Counter(c["module"] for c in final).most_common()),
    }

    output = {"candidates": final, "summary": summary}
    target = out_dir.parent / "candidates.json"
    target.write_text(json.dumps(output, indent=2, sort_keys=False))
    print(f"wrote {len(final)} candidates to {target}")
    print(f"  main: {summary['main']}  test: {summary['test']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
