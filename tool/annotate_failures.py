#!/usr/bin/env python3
"""Turn a `flutter test` log into GitHub Actions error annotations.

CI logs are not readable without repository access, but annotations are, so
failures are condensed into annotations instead. Annotations must be a single
line with no control characters, and GitHub renders only the first ten.

Usage: python3 tool/annotate_failures.py <logfile>
"""
import re
import sys

ANSI = re.compile(r"\x1b\[[0-9;]*m")
LOCATION = re.compile(r"\.dart:\d+:\d+")
# `flutter test` marks a failing test by appending [E] to its progress line,
# which is where the test name lives.
FAILED_TEST = re.compile(r"\[E\]\s*$")
SUMMARY = re.compile(r"(Some tests failed|All tests passed|\d+ tests? (passed|failed))")
MAX_ANNOTATIONS = 10
MAX_LEN = 400

INTERESTING = ("Expected:", "Actual:", "Which:", "Error:", "Exception:")


def clean(raw: str) -> str:
    return ANSI.sub("", raw).replace("\r", "").strip()


def main() -> int:
    path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/test.log"
    try:
        with open(path, errors="replace") as handle:
            lines = handle.read().replace("\r", "\n").split("\n")
    except OSError as error:
        print(f"::error::could not read {path}: {error}")
        return 1

    # Which tests failed is more actionable than interleaved stack frames, so
    # the names are collected first and given priority in the annotations.
    names, details, seen_names, seen_details = [], [], set(), set()
    for raw in lines:
        line = clean(raw)
        if not line:
            continue
        if FAILED_TEST.search(line):
            # Trim the leading progress counter and the trailing marker.
            name = re.sub(r"^\d\d:\d\d \+\d+( -\d+)?: ", "", line)
            name = re.sub(r"\s*\[E\]$", "", name).strip()
            name = name.replace("/home/runner/work/Rawnq/Rawnq/", "")
            if name and name not in seen_names:
                seen_names.add(name)
                names.append(name)
        elif line.startswith(INTERESTING):
            if line not in seen_details:
                seen_details.add(line)
                details.append(line)

    summaries = [clean(line) for line in lines if SUMMARY.search(line)]

    budget = MAX_ANNOTATIONS - (1 if summaries else 0)
    emitted = 0
    for name in names[:budget]:
        print(f"::error::FAILED {name[:MAX_LEN]}")
        emitted += 1
    # Fill any spare slots with the first concrete expectations.
    for detail in details[: max(0, budget - emitted)]:
        print(f"::error::{detail[:MAX_LEN]}")
        emitted += 1
    if summaries:
        extra = f" ({len(names)} distinct failing tests)" if len(names) > budget else ""
        print(f"::error::{summaries[-1][:MAX_LEN]}{extra}")
    if not names and not details and not summaries:
        print("::error::Tests failed but no failure lines were recognised.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
